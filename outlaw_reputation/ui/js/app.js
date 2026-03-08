const app = document.getElementById('app');
const requestPopup = document.getElementById('requestPopup');
const requestMessage = document.getElementById('requestMessage');
const playerRank = document.getElementById('playerRank');

const tabButtons = Array.from(document.querySelectorAll('.tab-btn'));
const tabPanels = Array.from(document.querySelectorAll('.tab-panel'));

let currentRequestId = null;

const REP_CATEGORIES = [
  { key: 'smuggler', label: 'Smuggler', icon: '📦' },
  { key: 'gunrunner', label: 'Gunrunner', icon: '🔫' },
  { key: 'thief', label: 'Thief', icon: '🕵️' },
  { key: 'mercenary', label: 'Mercenary', icon: '⚔️' }
];

function postNui(route, payload = {}) {
  fetch(`https://${GetParentResourceName()}/${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function getRepValue(data, key) {
  return Number(data.reputations?.[key]) || 0;
}

function getTotalRep(data) {
  return REP_CATEGORIES.reduce((sum, c) => sum + getRepValue(data, c.key), 0);
}

function getRankByRep(totalRep) {
  if (totalRep >= 3000) return 'Rank: Apex Kingpin';
  if (totalRep >= 2000) return 'Rank: Underworld Elite';
  if (totalRep >= 1000) return 'Rank: Trusted Operator';
  if (totalRep >= 400) return 'Rank: Street Veteran';
  return 'Rank: Street Prospect';
}

function renderRepCards(data) {
  return `
    <div class="grid">
      ${REP_CATEGORIES.map((category) => {
        const value = getRepValue(data, category.key);
        const progress = clamp(Math.floor((value % 1000) / 10), 0, 100);
        const level = Math.max(1, Math.floor(value / 100) + 1);

        return `
          <article class="stat-card">
            <div class="stat-top">
              <div class="label"><span>${category.icon}</span><span>${category.label}</span></div>
              <span class="level">Lvl ${level}</span>
            </div>
            <div class="progress"><span style="width:${progress}%"></span></div>
            <div class="meta">
              <span>Reputation</span>
              <span>${value}</span>
            </div>
          </article>
        `;
      }).join('')}
    </div>
  `;
}

function setTab(tabId) {
  tabButtons.forEach((btn) => btn.classList.toggle('active', btn.dataset.tab === tabId));
  tabPanels.forEach((panel) => panel.classList.toggle('active', panel.id === tabId));
}

function renderDashboard(data) {
  const totalRep = getTotalRep(data);
  playerRank.textContent = getRankByRep(totalRep);

  document.getElementById('overview').innerHTML = `
    <div class="kpi-row">
      <article class="kpi"><h3>Total Reputation</h3><p>${totalRep}</p></article>
      <article class="kpi"><h3>Best Category</h3><p>${[...REP_CATEGORIES].sort((a,b)=>getRepValue(data,b.key)-getRepValue(data,a.key))[0].label}</p></article>
      <article class="kpi"><h3>Active Status</h3><p><span class="badge">● Mission Ready</span></p></article>
    </div>
    ${renderRepCards(data)}
  `;

  document.getElementById('reputation').innerHTML = renderRepCards(data);

  document.getElementById('contracts').innerHTML = `
    <article class="list-card">
      <h3>Live Contracts</h3>
      <ol class="compact-list">
        <li>Port delivery route - High risk</li>
        <li>Arms exchange in Vinewood district</li>
        <li>Silent retrieval operation</li>
      </ol>
    </article>
  `;

  document.getElementById('progression').innerHTML = `
    <article class="list-card">
      <h3>Progression Goals</h3>
      <ol class="compact-list">
        <li>Reach 1500 total reputation</li>
        <li>Unlock Gunrunner Level 10</li>
        <li>Complete 5 premium contracts</li>
      </ol>
    </article>
  `;

  document.getElementById('statistics').innerHTML = `
    <div class="kpi-row">
      <article class="kpi"><h3>Success Rate</h3><p>89%</p></article>
      <article class="kpi"><h3>Ops Completed</h3><p>42</p></article>
      <article class="kpi"><h3>Weekly Gain</h3><p>+185</p></article>
    </div>
    <article class="list-card">
      <h3>Performance Notes</h3>
      <ul class="compact-list">
        <li>Strong consistency in Mercenary operations</li>
        <li>Smuggler line trending above average</li>
        <li>Thief profile needs reinforcement</li>
      </ul>
    </article>
  `;

  setTab('overview');
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data;

  if (action === 'open') {
    app.classList.remove('hidden');
    renderDashboard(data || {});
  }

  if (action === 'close') {
    app.classList.add('hidden');
  }

  if (action === 'request') {
    currentRequestId = data.requestId;
    requestMessage.textContent = data.message;
    requestPopup.classList.remove('hidden');
  }
});

tabButtons.forEach((btn) => {
  btn.addEventListener('click', () => setTab(btn.dataset.tab));
});

document.getElementById('closeBtn').addEventListener('click', () => {
  app.classList.add('hidden');
  postNui('close');
});

document.getElementById('acceptBtn').addEventListener('click', () => {
  requestPopup.classList.add('hidden');
  postNui('respondRequest', { requestId: currentRequestId, accepted: true });
});

document.getElementById('declineBtn').addEventListener('click', () => {
  requestPopup.classList.add('hidden');
  postNui('respondRequest', { requestId: currentRequestId, accepted: false });
});
