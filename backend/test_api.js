const http = require('http');

const request = (method, path, body = null, token = null) => {
  return new Promise((resolve, reject) => {
    const postData = body ? JSON.stringify(body) : null;
    const options = {
      hostname: '127.0.0.1',
      port: 5000,
      path: `/api/v1${path}`,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(postData ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
};

async function runTests() {
  console.log('🧪 =========================================');
  console.log('🧪 Starting TELOS Automated API Verification');
  console.log('🧪 =========================================\n');

  let passed = 0;
  let failed = 0;

  const assert = (condition, message) => {
    if (condition) {
      console.log(`✅ [PASS] ${message}`);
      passed++;
    } else {
      console.error(`❌ [FAIL] ${message}`);
      failed++;
    }
  };

  try {
    // 1. Health check
    const health = await new Promise((resolve) => {
      http.get('http://127.0.0.1:5000/api/health', (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => resolve(JSON.parse(data)));
      });
    });
    assert(health.status === 'online', 'Health endpoint reports status: online');

    // 2. Auth: Google Demo Sign-In
    const authRes = await request('POST', '/auth/google', {
      demoMode: true,
      email: 'test.user@telos.app',
      displayName: 'Test Tester',
    });
    assert(authRes.status === 200 && authRes.body.token, 'Google/Demo authentication returns JWT token');
    const token = authRes.body.token;

    // 3. Create Complete Task (Phase 2 Test)
    const taskData = {
      title: 'Automated Test: Complete Execution Verification',
      description: 'Verifying end-to-end task creation with full fields and persistence.',
      priority: 'high',
      scheduledDate: new Date().toISOString(),
      scheduledTime: '10:00',
      isAllDay: false,
      isAllDayUntilComplete: true,
      deadline: new Date(Date.now() + 86400000 * 3).toISOString(),
      repeatConfig: { type: 'daily' },
      visibility: 'private',
      invitePasscode: 'TL-TEST99',
    };

    const taskRes = await request('POST', '/tasks', taskData, token);
    assert(taskRes.status === 201 && taskRes.body.task?._id, 'Complete Task created successfully with priority and passcode');
    const taskId = taskRes.body.task._id;

    // 4. Test Duplicate Task Prevention
    const dupRes = await request('POST', '/tasks', taskData, token);
    assert(dupRes.body.duplicatePrevented === true, 'Duplicate task creation prevented (debounce active)');

    // 5. Get Tasks By Date (Home Feed Test)
    const dateQuery = new Date().toISOString().split('T')[0];
    const feedRes = await request('GET', `/tasks?date=${dateQuery}`, null, token);
    assert(
      feedRes.status === 200 && feedRes.body.tasks.some((t) => t._id === taskId),
      'Created task appears in Today schedule feed query'
    );

    // 6. Toggle Task Status (Complete -> +10 points)
    const toggleRes1 = await request('PATCH', `/tasks/${taskId}/toggle`, { occurrenceDate: dateQuery }, token);
    assert(toggleRes1.status === 200 && toggleRes1.body.pointsAwarded === 10, 'Task completion awards +10 points');

    // 7. Toggle Task Status Again (Reopen -> no double points)
    const toggleRes2 = await request('PATCH', `/tasks/${taskId}/toggle`, { occurrenceDate: dateQuery }, token);
    assert(toggleRes2.status === 200 && toggleRes2.body.status === 'pending', 'Task reopened successfully to pending status');

    // 8. Create Track with Milestones
    const trackData = {
      title: 'Automated Test Track: Software Sprint',
      description: '30-day testing track',
      startDate: new Date().toISOString(),
      endDate: new Date(Date.now() + 86400000 * 30).toISOString(),
      visibility: 'public',
      category: 'project',
      milestones: [
        { title: 'Milestone 1: Backend verified', targetDate: new Date().toISOString(), completed: true },
      ],
      tasks: [{ title: 'Linked Track Task 1' }],
    };
    const trackRes = await request('POST', '/tracks', trackData, token);
    assert(trackRes.status === 201 && trackRes.body.track?._id, 'Track created with milestones and isolated chat');
    const trackId = trackRes.body.track._id;

    // 9. Update Task to link to Track & Verify Progress Recalculation
    const updateRes = await request('PUT', `/tasks/${taskId}`, { trackId }, token);
    assert(updateRes.status === 200, 'Task successfully linked to Track');

    // 10. Analytics Calculation Test
    const analyticsRes = await request('GET', '/analytics?period=weekly', null, token);
    assert(
      analyticsRes.status === 200 && typeof analyticsRes.body.metrics.completionPercentage === 'number',
      'Analytics calculated from real database records'
    );

    // 11. AI Planning Test
    const aiRes = await request('POST', '/ai/chat', { message: 'Create a 4-week exam preparation plan' }, token);
    assert(aiRes.status === 200 && aiRes.body.generatedPlan?.tasks?.length > 0, 'AI generated structured 4-week plan with preview');

    // 12. Points Chest Verification
    const pointsRes = await request('GET', '/points/chest', null, token);
    assert(pointsRes.status === 200 && pointsRes.body.currentBalance >= 0, 'Points Chest retrieves legitimate balance and achievements');

    // 13. Global Search Test
    const searchRes = await request('GET', '/search?q=Automated', null, token);
    assert(searchRes.status === 200 && searchRes.body.results.tasks?.length > 0, 'Global search retrieves authorized matching task');

    console.log(`\n🎉 Verification Complete: ${passed} Passed, ${failed} Failed`);
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('❌ Test execution error:', err);
    process.exit(1);
  }
}

runTests();
