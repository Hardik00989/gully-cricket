const project = 'demo-gully-cricket';
const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
if (!['127.0.0.1:8080', 'localhost:8080'].includes(host)) throw new Error('This seed script only writes to a local emulator.');
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
function encode(value) {
  if (value instanceof Date) return {timestampValue: value.toISOString()};
  if (Array.isArray(value)) return {arrayValue: {values: value.map(encode)}};
  if (typeof value === 'number') return {integerValue: String(value)};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (value && typeof value === 'object') return {mapValue: {fields: fields(value)}};
  return {stringValue: value ?? ''};
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k,v]) => [k,encode(v)])); }
async function put(path, data) {
  const response = await fetch(`${base}/${path}`, {method: 'PATCH', headers: {'Content-Type': 'application/json', Authorization: 'Bearer owner'}, body: JSON.stringify({fields: fields(data)})});
  if (!response.ok) throw new Error(await response.text());
}
async function exists(path) {
  const response = await fetch(`${base}/${path}`, {headers:{Authorization:'Bearer owner'}});
  if (response.status === 404) return false;
  if (!response.ok) throw new Error(await response.text());
  return true;
}
const now = new Date();
await put('tournaments/shivaji-cup', {name:'Shivaji Ground Cup', location:'Pune', startDate: now, endDate: new Date(+now + 604800000), format:'T10', status:'ongoing', createdBy:'demo-admin'});
const names = [['shivaji-strikers','Shivaji Strikers','SS'],['kothrud-kings','Kothrud Kings','KK'],['deccan-warriors','Deccan Warriors','DW']];
for (const [id,name,shortName] of names) {
  await put(`teams/${id}`, {name,shortName,logoUrl:'',tournamentIds:['shivaji-cup']});
  const first = ['Aarav','Vihaan','Aditya','Arjun','Ishaan','Kabir','Rohan','Sahil','Pranav','Omkar','Yash'];
  for (let i=0;i<11;i++) await put(`teams/${id}/players/player-${i+1}`, {name:`${first[i]} ${id === 'shivaji-strikers' ? 'Patil' : id === 'kothrud-kings' ? 'Deshmukh' : 'Jadhav'}`,role:i===0?'keeper':i>6?'bowler':i>3?'allrounder':'batter',jerseyNo:i+1});
}
const fixture = {tournamentId:'shivaji-cup',teamAId:names[0][0],teamBId:names[1][0],teamAName:names[0][1],teamBName:names[1][1],teamAShort:'SS',teamBShort:'KK',venue:'Shivaji Ground, Pune',scheduledAt:new Date(+now+3600000),overs:10,status:'upcoming',innings:[],currentInnings:0,revision:0};
if (!await exists('matches/cup-opener')) await put('matches/cup-opener',fixture);
if (!await exists('matches/evening-fixture')) await put('matches/evening-fixture',{...fixture,teamAId:names[2][0],teamAName:names[2][1],teamAShort:'DW',scheduledAt:new Date(+now+86400000)});
async function scoredMatch(id, inningsRuns) {
  if (await exists(`matches/${id}`)) return;
  const completed = inningsRuns.length === 2;
  let match={...fixture,overs:completed?1:10,scheduledAt:new Date(+now+(completed?-7200000:-600000)),status:'live',revision:0,innings:[],result:{},lastBallId:'',toss:{winnerTeamId:fixture.teamAId,decision:'bat'}};
  for (let innings=0;innings<inningsRuns.length;innings++) {
    let striker='player-1',nonStriker='player-2';
    const surname=innings===0?'Patil':'Deshmukh', bowlingSurname=innings===0?'Deshmukh':'Patil';
    let state={battingTeamId:innings===0?fixture.teamAId:fixture.teamBId,strikerId:striker,nonStrikerId:nonStriker,bowlerId:'player-7',runs:0,wickets:0,balls:0,extras:0,closed:false,awaitingBowler:false,freeHit:false,dismissed:[]};
    const names=()=>({strikerName:`${striker==='player-1'?'Aarav':'Vihaan'} ${surname}`,nonStrikerName:`${nonStriker==='player-1'?'Aarav':'Vihaan'} ${surname}`,bowlerName:`Rohan ${bowlingSurname}`});
    match={...match,revision:match.revision+1,currentInnings:innings,lastBallId:'',...names(),innings:[...match.innings,{...state,...names()}]};
    for (const runs of inningsRuns[innings]) {
      const before=structuredClone(Object.fromEntries(['innings','currentInnings','status','result','strikerName','nonStrikerName','bowlerName','lastBallId'].map(k=>[k,match[k]])));
      const ballId=`seed-${String(match.revision+1).padStart(5,'0')}`;
      await put(`matches/${id}/balls/${ballId}`,{innings,over:state.balls/6|0,ballInOver:state.balls%6+1,batterId:striker,bowlerId:'player-7',batterName:match.strikerName,bowlerName:match.bowlerName,runsOffBat:runs,extraType:'none',extraRuns:0,isWicket:false,wicketType:'',dismissedPlayerId:'',createdAt:now,sequence:match.revision+1,before});
      const balls=state.balls+1;
      if(runs%2===1) [striker,nonStriker]=[nonStriker,striker];
      if(balls%6===0) [striker,nonStriker]=[nonStriker,striker];
      state={...state,runs:state.runs+runs,balls,strikerId:striker,nonStrikerId:nonStriker,closed:balls===match.overs*6};
      match.innings[innings]={...state,...names()};
      match={...match,revision:match.revision+1,lastBallId:ballId,...names()};
    }
  }
  if(completed) match={...match,status:'completed',result:{winnerTeamId:fixture.teamAId,summary:'Shivaji Strikers won by 4 runs'}};
  await put(`matches/${id}`,match);
}
await scoredMatch('ground-live',[[4,0,6]]);
await scoredMatch('morning-result',[[4,0,0,0,0,0],[0,0,0,0,0,0]]);
const signup = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-api-key',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@gully.local',password:'Cricket123!',returnSecureToken:true})});
let account = await signup.json();
if (!signup.ok && account.error?.message === 'EMAIL_EXISTS') {
  const login = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-api-key',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@gully.local',password:'Cricket123!',returnSecureToken:true})});
  account = await login.json();
}
if (!account.localId) throw new Error(JSON.stringify(account));
await put(`users/${account.localId}`,{name:'Tournament Admin',email:'admin@gully.local',role:'admin',createdAt:now});
console.log('Seeded local emulator. Admin: admin@gully.local / Cricket123!');
