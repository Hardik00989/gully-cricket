import {readFile} from 'node:fs/promises';
import {after,before,beforeEach,test} from 'node:test';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {setDoc,getDoc,getDocs,collection as rawCollection,doc as rawDoc,updateDoc,deleteDoc} from 'firebase/firestore';
const root=process.env.RULES_ROOT ?? '';
const rulesFile=process.env.RULES_FILE ?? 'firestore.rules';
const doc=(db,path)=>rawDoc(db,root ? root+'/'+path : path);
const collection=(db,path)=>rawCollection(db,root ? root+'/'+path : path);
let env;
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-gully-cricket',firestore:{rules:await readFile(rulesFile,'utf8')}});});
after(async()=>{await env?.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    await setDoc(doc(db,'users/admin'),{role:'admin',name:'Admin',email:'admin@test.local'});
    await setDoc(doc(db,'users/viewer'),{role:'user',name:'Viewer',email:'viewer@test.local'});
    await setDoc(doc(db,'users/subject'),{role:'user',name:'Subject',email:'subject@test.local'});
    await setDoc(doc(db,'matches/match'),{status:'live'});
    await setDoc(doc(db,'teams/other-team'),{name:'Other team',createdBy:'someone-else'});
  });
});
test('guests retain public reads including squads and balls',async()=>{
  const db=env.unauthenticatedContext().firestore();
  for(const path of ['tournaments/cup','teams/other-team','teams/other-team/players/p','matches/match','matches/match/balls/b'])await assertSucceeds(getDoc(doc(db,path)));
});
test('guests cannot write or access user profiles',async()=>{
  const db=env.unauthenticatedContext().firestore();
  for(const path of ['tournaments/cup','teams/other-team','teams/other-team/players/p','matches/match','matches/match/balls/b','users/viewer'])await assertFails(setDoc(doc(db,path),{name:'Denied'}));
  await assertFails(getDoc(doc(db,'users/viewer')));
  await assertFails(getDocs(collection(db,'users')));
});
test('ordinary users and stored admins have equal create edit and delete permissions',async()=>{
  for(const uid of ['viewer','admin']){
    const db=env.authenticatedContext(uid).firestore();
    for(const path of ['tournaments/'+uid,'teams/'+uid,'teams/other-team/players/'+uid,'matches/'+uid,'matches/match/balls/'+uid]){
      await assertSucceeds(setDoc(doc(db,path),{name:'Created',createdBy:uid}));
      await assertSucceeds(updateDoc(doc(db,path),{name:'Updated'}));
      await assertSucceeds(deleteDoc(doc(db,path)));
    }
  }
});
test('a regular user can edit another team and score or finish matches',async()=>{
  const db=env.authenticatedContext('viewer').firestore();
  await assertSucceeds(updateDoc(doc(db,'teams/other-team'),{name:'Updated team'}));
  await assertSucceeds(updateDoc(doc(db,'matches/match'),{status:'completed',result:{summary:'Finished'}}));
});
test('all signed-in users can list accounts and change another account role',async()=>{
  const db=env.authenticatedContext('viewer').firestore();
  await assertSucceeds(getDocs(collection(db,'users')));
  await assertSucceeds(getDoc(doc(db,'users/admin')));
  await assertSucceeds(updateDoc(doc(db,'users/subject'),{role:'admin'}));
  await assertSucceeds(updateDoc(doc(db,'users/subject'),{role:'user'}));
  await assertSucceeds(deleteDoc(doc(db,'users/subject')));
});
test('signup still creates the correct own user profile without forged emails',async()=>{
  const db=env.authenticatedContext('new-user',{email:'new@test.local'}).firestore();
  await assertFails(setDoc(doc(db,'users/new-user'),{name:'New',email:'new@test.local',role:'admin'}));
  await assertFails(setDoc(doc(db,'users/new-user'),{name:'New',email:'forged@test.local',role:'user'}));
  await assertFails(setDoc(doc(db,'users/someone-else'),{name:'New',email:'new@test.local',role:'user'}));
  await assertSucceeds(setDoc(doc(db,'users/new-user'),{name:'New',email:'new@test.local',role:'user'}));
});
test('signed-in accounts do not need a stored admin role for temporary management',async()=>{
  await assertSucceeds(setDoc(doc(env.authenticatedContext('no-profile').firestore(),'tournaments/new'),{name:'New cup'}));
});
test('the existing restriction on deleting your own account profile remains',async()=>{
  for(const uid of ['viewer','admin'])await assertFails(deleteDoc(doc(env.authenticatedContext(uid).firestore(),'users/'+uid)));
});
test('unknown collections and unrelated legacy namespaces stay protected',async()=>{
  for(const uid of ['viewer','admin'])await assertFails(setDoc(doc(env.authenticatedContext(uid).firestore(),'secrets/key'),{value:'x'}));
  if(root){
    const db=env.authenticatedContext('viewer').firestore();
    await assertFails(setDoc(rawDoc(db,'teams/legacy-team'),{name:'Denied'}));
    await assertFails(setDoc(rawDoc(db,'admins/viewer'),{role:'admin'}));
  }
});
test('turning off the temporary rules flag restores stored role enforcement',async()=>{
  const normalRules=(await readFile(rulesFile,'utf8')).replace('function temporaryFullUserAccess() { return true; }','function temporaryFullUserAccess() { return false; }');
  const restricted=await initializeTestEnvironment({projectId:'demo-gully-cricket',firestore:{rules:normalRules}});
  try{
    await assertFails(updateDoc(doc(restricted.authenticatedContext('viewer').firestore(),'matches/match'),{status:'completed'}));
    await assertFails(getDocs(collection(restricted.authenticatedContext('viewer').firestore(),'users')));
    await assertSucceeds(updateDoc(doc(restricted.authenticatedContext('admin').firestore(),'matches/match'),{status:'completed'}));
  }finally{
    await restricted.cleanup();
    const restored=await initializeTestEnvironment({projectId:'demo-gully-cricket',firestore:{rules:await readFile(rulesFile,'utf8')}});
    await restored.cleanup();
  }
});

