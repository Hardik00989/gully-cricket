import {chromium,expect} from '@playwright/test';
const base=process.env.PROBE_URL ?? 'http://127.0.0.1:7358';
if(!['127.0.0.1','localhost'].includes(new URL(base).hostname)) throw new Error('The integration probe must use a local server.');
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
  const page=await browser.newPage();
  page.on('pageerror',e=>console.error(e.message));
  await page.goto(base);
  await page.waitForSelector('flutter-view',{timeout:90000});
  if(await page.locator('flt-semantics-placeholder').count()) await page.locator('flt-semantics-placeholder').evaluate(el=>el.click());
  const result=page.getByText(/^SCORING_PROBE /);
  await expect(result).toBeVisible({timeout:90000});
  await expect(result).toHaveText('SCORING_PROBE PASS');
  console.log('PASS: atomic scoring, concurrent-write rejection, undo, player names, chase completion and standings.');
} finally {await browser.close();}
