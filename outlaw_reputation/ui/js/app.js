const app = document.getElementById('app');
const playerRep = document.getElementById('playerRep');
const companyPanel = document.getElementById('companyPanel');
const leaderboard = document.getElementById('leaderboard');
const policeRecord = document.getElementById('policeRecord');
const requestPopup = document.getElementById('requestPopup');
const requestMessage = document.getElementById('requestMessage');

let currentRequestId = null;

function postNui(route, payload = {}) {
  fetch(`https://${GetParentResourceName()}/${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
}

function renderDashboard(data) {
  playerRep.innerHTML = '';
  companyPanel.innerHTML = '';
  leaderboard.innerHTML = '';

  const types = data.repTypes || {};
  Object.entries(types).forEach(([key, info]) => {
    const li = document.createElement('li');
    li.textContent = `${info.icon} ${info.label}: ${data.reputations?.[key] || 0}`;
    playerRep.appendChild(li);
  });

  companyPanel.innerHTML = `
    <p><strong>Société:</strong> ${data.company?.name || 'Aucune'}</p>
    <p><strong>Réputation société:</strong> ${data.company?.rep || 0}</p>
    <p><strong>Contributeurs:</strong></p>
    <ul>${(data.company?.contributions || []).slice(0, 5).map(x => `<li>${x.identifier}: ${x.rep}</li>`).join('')}</ul>
  `;

  (data.leaderboard || []).forEach((entry) => {
    const li = document.createElement('li');
    li.textContent = `${entry.identifier}: ${entry.value}`;
    leaderboard.appendChild(li);
  });

  policeRecord.innerHTML = data.policeRecord
    ? `<p>Crime connu: ${data.policeRecord.known_crime_rep}</p><p>Dernière MAJ: ${data.policeRecord.last_update}</p>`
    : '<p>Aucun dossier.</p>';
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
