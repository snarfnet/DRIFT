const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');

const KEY_ID = process.env.ASC_KEY_ID || 'WDXGY9WX55';
const ISSUER_ID = process.env.ASC_ISSUER_ID || '2be0734f-943a-4d61-9dc9-5d9045c46fec';
const API_KEY_PATH = process.env.ASC_KEY_PATH || `${process.env.HOME || process.env.USERPROFILE}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;
const APP_ID = process.env.ASC_APP_ID || '6770727208';
const VERSION_STRING = process.env.APP_VERSION || '1.0';
const LOCALE = process.env.APP_LOCALE || 'ja';
const ROOT = path.resolve(__dirname, '..');

const metadata = {
  promotionalText: 'テンポ、強度、キーを選ぶだけで、廃墟の奥から鳴るようなテクノループを生成します。',
  description: [
    'DRIFTは、テンポ、強度、キー、スタイルを選ぶだけでテクノパターンを生成する音楽アプリです。',
    '',
    'DRIFT、DEEP、MINIMALの3つのモードを切り替えながら、キック、スネア、ハイハット、ベース、メロディを組み合わせます。生成したパターンはその場で再生できます。',
    '',
    '画面は、森に覆われた廃墟の中に残った音響機材をイメージしたデザインです。大きなジョグ、16ステップ表示、光る再生位置で、いま鳴っているリズムを見ながら操作できます。',
    '',
    '主な機能',
    '',
    '- テンポ調整',
    '- 強度調整',
    '- キー選択',
    '- DRIFT / DEEP / MINIMAL モード',
    '- 自動ドラムパターン生成',
    '- ベースライン生成',
    '- メロディ生成',
    '- 16ステップシーケンサー表示',
    '- AVAudioEngineによるリアルタイム再生',
    '',
    '短いループのアイデア出し、テクノの雰囲気作り、音のスケッチに使えます。',
  ].join('\n'),
  keywords: 'テクノ,自動作曲,シンセ,ドラム,シーケンサー,ミニマル,音楽制作,BPM,ループ',
  supportUrl: 'https://snarfnet.github.io/DRIFT/',
  marketingUrl: 'https://snarfnet.github.io/DRIFT/',
};

const appInfoMetadata = {
  subtitle: '自動テクノ生成エンジン',
  privacyPolicyUrl: 'https://github.com/snarfnet/DRIFT/blob/main/docs/privacy-policy.md',
};

function makeJWT() {
  const key = fs.readFileSync(API_KEY_PATH, 'utf8');
  const now = Math.floor(Date.now() / 1000) - 60;
  const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ iss: ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })).toString('base64url');
  const sign = crypto.createSign('SHA256');
  sign.update(`${header}.${payload}`);
  sign.end();
  return `${header}.${payload}.${sign.sign({ key, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
}

function api(method, requestPath, body = undefined, extraHeaders = {}) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = https.request({
      hostname: 'api.appstoreconnect.apple.com',
      path: requestPath,
      method,
      headers: {
        Authorization: `Bearer ${makeJWT()}`,
        'Content-Type': 'application/json',
        ...extraHeaders,
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    }, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        let parsed = raw;
        try { parsed = raw ? JSON.parse(raw) : {}; } catch {}
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(parsed);
        else reject(new Error(`HTTP ${res.statusCode} ${method} ${requestPath}\n${JSON.stringify(parsed, null, 2)}`));
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function upload(url, method, headers, body) {
  return new Promise((resolve, reject) => {
    const target = new URL(url);
    const req = https.request({
      hostname: target.hostname,
      path: `${target.pathname}${target.search}`,
      method,
      headers: { ...headers, 'Content-Length': body.length },
    }, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(raw);
        else reject(new Error(`Upload failed ${res.statusCode} ${method} ${url}\n${raw}`));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function getAppStoreVersion() {
  const response = await api('GET', `/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10`);
  const existing = response.data.find((version) => version.attributes.versionString === VERSION_STRING)
    || response.data.find((version) => version.attributes.appStoreState === 'PREPARE_FOR_SUBMISSION');
  if (existing) return existing;

  return (await api('POST', '/v1/appStoreVersions', {
    data: {
      type: 'appStoreVersions',
      attributes: {
        platform: 'IOS',
        versionString: VERSION_STRING,
        releaseType: 'AFTER_APPROVAL',
      },
      relationships: {
        app: { data: { type: 'apps', id: APP_ID } },
      },
    },
  })).data;
}

async function getLocalization(versionId) {
  const response = await api('GET', `/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=10`);
  const localization = response.data.find((item) => item.attributes.locale === LOCALE)
    || response.data.find((item) => item.attributes.locale.startsWith('ja'))
    || response.data[0];
  if (localization) return localization;

  return (await api('POST', '/v1/appStoreVersionLocalizations', {
    data: {
      type: 'appStoreVersionLocalizations',
      attributes: { locale: LOCALE },
      relationships: {
        appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } },
      },
    },
  })).data;
}

async function updateLocalization(localizationId) {
  await api('PATCH', `/v1/appStoreVersionLocalizations/${localizationId}`, {
    data: {
      type: 'appStoreVersionLocalizations',
      id: localizationId,
      attributes: metadata,
    },
  });
}

async function updateAppInfoLocalization() {
  const infos = await api('GET', `/v1/apps/${APP_ID}/appInfos?limit=10`);
  const info = infos.data[0];
  if (!info) return;

  const localizations = await api('GET', `/v1/appInfos/${info.id}/appInfoLocalizations?limit=10`);
  const localization = localizations.data.find((item) => item.attributes.locale === LOCALE)
    || localizations.data.find((item) => item.attributes.locale.startsWith('ja'))
    || localizations.data[0];
  if (!localization) return;

  await api('PATCH', `/v1/appInfoLocalizations/${localization.id}`, {
    data: {
      type: 'appInfoLocalizations',
      id: localization.id,
      attributes: {
        ...appInfoMetadata,
        name: localization.attributes.name || 'DRIFT Techno Engine',
      },
    },
  });
}

async function getOrCreateScreenshotSet(localizationId, screenshotDisplayType) {
  const response = await api('GET', `/v1/appStoreVersionLocalizations/${localizationId}/appScreenshotSets?limit=20`);
  const existing = response.data.find((set) => set.attributes.screenshotDisplayType === screenshotDisplayType);
  if (existing) return existing;

  return (await api('POST', '/v1/appScreenshotSets', {
    data: {
      type: 'appScreenshotSets',
      attributes: { screenshotDisplayType },
      relationships: {
        appStoreVersionLocalization: {
          data: { type: 'appStoreVersionLocalizations', id: localizationId },
        },
      },
    },
  })).data;
}

async function deleteScreenshots(setId) {
  const response = await api('GET', `/v1/appScreenshotSets/${setId}/appScreenshots?limit=10`);
  for (const screenshot of response.data) {
    await api('DELETE', `/v1/appScreenshots/${screenshot.id}`);
  }
}

async function createScreenshot(setId, filePath) {
  const buffer = fs.readFileSync(filePath);
  const fileName = path.basename(filePath);
  const checksum = crypto.createHash('md5').update(buffer).digest('base64');
  const created = (await api('POST', '/v1/appScreenshots', {
    data: {
      type: 'appScreenshots',
      attributes: {
        fileSize: buffer.length,
        fileName,
      },
      relationships: {
        appScreenshotSet: { data: { type: 'appScreenshotSets', id: setId } },
      },
    },
  })).data;

  for (const operation of created.attributes.uploadOperations) {
    const offset = Number(operation.offset || 0);
    const length = Number(operation.length || buffer.length);
    const part = buffer.subarray(offset, offset + length);
    const headers = Object.fromEntries((operation.requestHeaders || []).map((header) => [header.name, header.value]));
    await upload(operation.url, operation.method, headers, part);
  }

  await api('PATCH', `/v1/appScreenshots/${created.id}`, {
    data: {
      type: 'appScreenshots',
      id: created.id,
      attributes: {
        uploaded: true,
        sourceFileChecksum: checksum,
      },
    },
  });
}

async function uploadScreenshots(localizationId) {
  const screenshotGroups = [
    {
      displayType: 'APP_IPHONE_67',
      files: ['iphone-67-01-main.png', 'iphone-67-02-control.png', 'iphone-67-03-sequencer.png'],
    },
    {
      displayType: 'APP_IPAD_PRO_3GEN_129',
      files: ['ipad-13-01-main.png', 'ipad-13-02-control.png', 'ipad-13-03-sequencer.png'],
    },
  ];

  for (const group of screenshotGroups) {
    const set = await getOrCreateScreenshotSet(localizationId, group.displayType);
    await deleteScreenshots(set.id);
    for (const fileName of group.files) {
      await createScreenshot(set.id, path.join(ROOT, 'AppStoreAssets', 'screenshots', fileName));
    }
  }
}

async function latestProcessedBuild() {
  const response = await api('GET', `/v1/builds?filter[app]=${APP_ID}&sort=-uploadedDate&limit=10`);
  return response.data.find((build) => build.attributes.processingState === 'VALID') || response.data[0];
}

async function latestBuild() {
  const response = await api('GET', `/v1/builds?filter[app]=${APP_ID}&sort=-uploadedDate&limit=10`);
  return response.data[0] || null;
}

async function waitForProcessedBuild(expectedBuildNumber) {
  const expected = expectedBuildNumber ? String(expectedBuildNumber) : null;
  for (let attempt = 1; attempt <= 60; attempt += 1) {
    const build = await latestBuild();
    if (build) {
      const buildNumber = String(build.attributes.buildNumber || '');
      const state = build.attributes.processingState;
      console.log(`Build processing: ${build.attributes.version} (${buildNumber}) ${state} attempt ${attempt}/60`);
      if ((!expected || buildNumber === expected) && state === 'VALID') return build;
    }
    await delay(30000);
  }
  throw new Error(`Timed out waiting for processed build${expected ? ` ${expected}` : ''}.`);
}

async function attachBuild(versionId, build = null) {
  build = build || await latestProcessedBuild();
  if (!build || build.attributes.processingState !== 'VALID') return build || null;
  await api('PATCH', `/v1/appStoreVersions/${versionId}/relationships/build`, {
    data: { type: 'builds', id: build.id },
  }, { 'Content-Type': 'application/vnd.api+json' });
  try {
    await api('PATCH', `/v1/builds/${build.id}`, {
      data: {
        type: 'builds',
        id: build.id,
        attributes: { usesNonExemptEncryption: false },
      },
    });
  } catch (error) {
    if (!String(error.message).includes('already set')) throw error;
  }
  console.log(`Attached build: ${build.attributes.version} (${build.attributes.buildNumber})`);
  return build;
}

async function updateReviewDetails(versionId) {
  const response = await api('GET', `/v1/appStoreVersions/${versionId}/appStoreReviewDetail`);
  const detail = response.data;
  const payload = {
    data: {
      type: 'appStoreReviewDetails',
      attributes: {
        contactFirstName: 'DRIFT',
        contactLastName: 'Support',
        contactPhone: '+818023689194',
        contactEmail: 'tokyonasu@yahoo.co.jp',
        demoAccountRequired: false,
        demoAccountName: '',
        demoAccountPassword: '',
        notes: 'DRIFT is an automatic techno music generator. It uses AVAudioEngine for local audio playback and Google AdMob for banner ads. Login is not required. Generated patterns and playback happen on device.',
      },
    },
  };
  if (!detail) {
    payload.data.relationships = { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } };
    await api('POST', '/v1/appStoreReviewDetails', payload);
    return;
  }
  payload.data.id = detail.id;
  await api('PATCH', `/v1/appStoreReviewDetails/${detail.id}`, payload);
}

async function getAppInfo() {
  return (await api('GET', `/v1/apps/${APP_ID}/appInfos?limit=1`)).data[0];
}

async function updateAgeRatingAndCategory() {
  const appInfo = await getAppInfo();
  if (!appInfo) return;

  await api('PATCH', `/v1/ageRatingDeclarations/${appInfo.id}`, {
    data: {
      type: 'ageRatingDeclarations',
      id: appInfo.id,
      attributes: {
        alcoholTobaccoOrDrugUseOrReferences: 'NONE',
        contests: 'NONE',
        gamblingSimulated: 'NONE',
        gunsOrOtherWeapons: 'NONE',
        horrorOrFearThemes: 'NONE',
        matureOrSuggestiveThemes: 'NONE',
        medicalOrTreatmentInformation: 'NONE',
        profanityOrCrudeHumor: 'NONE',
        sexualContentGraphicAndNudity: 'NONE',
        sexualContentOrNudity: 'NONE',
        violenceCartoonOrFantasy: 'NONE',
        violenceRealistic: 'NONE',
        violenceRealisticProlongedGraphicOrSadistic: 'NONE',
        gambling: false,
        lootBox: false,
        unrestrictedWebAccess: false,
        messagingAndChat: false,
        ageAssurance: false,
        advertising: true,
        parentalControls: false,
        userGeneratedContent: false,
        healthOrWellnessTopics: false,
      },
    },
  });

  try {
    await api('PATCH', `/v1/appInfos/${appInfo.id}`, {
      data: {
        type: 'appInfos',
        id: appInfo.id,
        relationships: {
          primaryCategory: { data: { type: 'appCategories', id: 'MUSIC' } },
        },
      },
    });
  } catch (error) {
    console.log(`Category update skipped: ${error.message.split('\n')[0]}`);
  }
}

async function updateVersionAndAppRequirements(versionId) {
  await api('PATCH', `/v1/appStoreVersions/${versionId}`, {
    data: {
      type: 'appStoreVersions',
      id: versionId,
      attributes: {
        copyright: '2026 Tokyo Nasu',
      },
    },
  });

  await api('PATCH', `/v1/apps/${APP_ID}`, {
    data: {
      type: 'apps',
      id: APP_ID,
      attributes: {
        contentRightsDeclaration: 'DOES_NOT_USE_THIRD_PARTY_CONTENT',
      },
    },
  });
}

async function updatePricing() {
  const pricePoints = await api('GET', `/v1/apps/${APP_ID}/appPricePoints?filter[territory]=USA&limit=20`);
  const freePoint = pricePoints.data.find((point) => point.attributes.customerPrice === '0.0');
  if (!freePoint) return;
  try {
    await api('POST', '/v1/appPriceSchedules', {
      data: {
        type: 'appPriceSchedules',
        relationships: {
          app: { data: { type: 'apps', id: APP_ID } },
          manualPrices: { data: [{ type: 'appPrices', id: '${free-price}' }] },
          baseTerritory: { data: { type: 'territories', id: 'USA' } },
        },
      },
      included: [{
        type: 'appPrices',
        id: '${free-price}',
        attributes: { startDate: null },
        relationships: {
          appPricePoint: { data: { type: 'appPricePoints', id: freePoint.id } },
        },
      }],
    });
  } catch (error) {
    if (!String(error.message).includes('409')) throw error;
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function getReviewSubmissionItems(submissionId) {
  const response = await api('GET', `/v1/reviewSubmissions/${submissionId}/items?limit=20`);
  return response.data || [];
}

async function getOrCreateReviewSubmission() {
  const response = await api('GET', `/v1/reviewSubmissions?filter[app]=${APP_ID}&filter[platform]=IOS&limit=20`);
  const submissions = response.data || [];
  const active = submissions.find((submission) => ['WAITING_FOR_REVIEW', 'IN_REVIEW'].includes(submission.attributes.state));
  if (active) return { submission: active, alreadySubmitted: true };

  let reusable = null;
  for (const submission of submissions) {
    const state = submission.attributes.state;
    if (state === 'COMPLETE' || state === 'CANCELED') continue;

    const items = await getReviewSubmissionItems(submission.id);
    for (const item of items) {
      try {
        await api('DELETE', `/v1/reviewSubmissionItems/${item.id}`);
      } catch (error) {
        console.log(`Review item cleanup skipped: ${item.id}`);
      }
    }

    if (state === 'READY_FOR_REVIEW' && !reusable) {
      reusable = submission;
      continue;
    }

    try {
      await api('PATCH', `/v1/reviewSubmissions/${submission.id}`, {
        data: {
          type: 'reviewSubmissions',
          id: submission.id,
          attributes: { canceled: true },
        },
      });
    } catch (error) {
      console.log(`Review submission cleanup skipped: ${submission.id} (${state})`);
    }
  }

  if (reusable) return { submission: reusable, alreadySubmitted: false };

  const created = await api('POST', '/v1/reviewSubmissions', {
    data: {
      type: 'reviewSubmissions',
      attributes: { platform: 'IOS' },
      relationships: {
        app: { data: { type: 'apps', id: APP_ID } },
      },
    },
  });
  return { submission: created.data, alreadySubmitted: false };
}

async function submitForReview() {
  const version = await getAppStoreVersion();
  console.log(`Version: ${version.attributes.versionString} (${version.attributes.appStoreState})`);
  const build = process.env.EXPECT_BUILD_NUMBER
    ? await waitForProcessedBuild(process.env.EXPECT_BUILD_NUMBER)
    : null;
  await attachBuild(version.id, build);

  const { submission, alreadySubmitted } = await getOrCreateReviewSubmission();
  if (alreadySubmitted) {
    console.log(`Already submitted: ${submission.id} (${submission.attributes.state})`);
    return;
  }

  console.log(`Review submission: ${submission.id}`);
  let itemCreated = false;
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    try {
      await api('POST', '/v1/reviewSubmissionItems', {
        data: {
          type: 'reviewSubmissionItems',
          relationships: {
            reviewSubmission: { data: { type: 'reviewSubmissions', id: submission.id } },
            appStoreVersion: { data: { type: 'appStoreVersions', id: version.id } },
          },
        },
      });
      itemCreated = true;
      break;
    } catch (error) {
      if (attempt === 5) throw error;
      console.log(`Review item not ready, retrying (${attempt}/5)...`);
      await delay(15000);
    }
  }

  if (!itemCreated) throw new Error('Could not add app version to review submission.');

  for (let attempt = 1; attempt <= 5; attempt += 1) {
    const result = await api('PATCH', `/v1/reviewSubmissions/${submission.id}`, {
      data: {
        type: 'reviewSubmissions',
        id: submission.id,
        attributes: { submitted: true },
      },
    });
    const state = result.data?.attributes?.state;
    console.log(`Submission state: ${state || 'unknown'} (attempt ${attempt})`);
    if (state === 'WAITING_FOR_REVIEW' || state === 'IN_REVIEW') return;
    await delay(15000);
  }
}

async function sync(options = {}) {
  const { screenshots = true } = options;
  const version = await getAppStoreVersion();
  console.log(`Version: ${version.attributes.versionString} (${version.attributes.appStoreState})`);
  await updateAppInfoLocalization();
  await updateAgeRatingAndCategory();
  await updateVersionAndAppRequirements(version.id);
  await updatePricing();
  const localization = await getLocalization(version.id);
  await updateLocalization(localization.id);
  if (screenshots) await uploadScreenshots(localization.id);
  await updateReviewDetails(version.id);
  await attachBuild(version.id);
  console.log('DRIFT ASC sync completed.');
}

async function syncAndSubmit() {
  const version = await getAppStoreVersion();
  console.log(`Version: ${version.attributes.versionString} (${version.attributes.appStoreState})`);
  await updateAppInfoLocalization();
  await updateAgeRatingAndCategory();
  await updateVersionAndAppRequirements(version.id);
  await updatePricing();
  const localization = await getLocalization(version.id);
  await updateLocalization(localization.id);
  await uploadScreenshots(localization.id);
  await updateReviewDetails(version.id);
  const build = process.env.EXPECT_BUILD_NUMBER
    ? await waitForProcessedBuild(process.env.EXPECT_BUILD_NUMBER)
    : await waitForProcessedBuild(null);
  await attachBuild(version.id, build);
  await submitForReview();
}

async function status() {
  const app = await api('GET', `/v1/apps/${APP_ID}`);
  const versions = await api('GET', `/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10`);
  const builds = await api('GET', `/v1/builds?filter[app]=${APP_ID}&sort=-uploadedDate&limit=5`);
  const submissions = await api('GET', `/v1/reviewSubmissions?filter[app]=${APP_ID}&filter[platform]=IOS&limit=10`);
  console.log(JSON.stringify({
    app: app.data.attributes,
    versions: versions.data.map((version) => ({ id: version.id, versionString: version.attributes.versionString, state: version.attributes.appStoreState })),
    builds: builds.data.map((build) => ({ id: build.id, version: build.attributes.version, buildNumber: build.attributes.buildNumber, state: build.attributes.processingState })),
    submissions: submissions.data.map((submission) => ({ id: submission.id, state: submission.attributes.state })),
  }, null, 2));
}

const command = process.argv[2] || 'status';
const actions = { sync, status, submit: submitForReview, 'sync-submit': syncAndSubmit };
(actions[command] || status)().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
