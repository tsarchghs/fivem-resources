// html/script.js

window.addEventListener('message', function(event) {
    var data = event.data;
    if (data.action === 'showUI') {
        // Show the HUD (was hidden by default)
        document.body.style.display = 'block';
    }
    else if (data.action === 'updateMoney') {
        // Update cash and bank values
        document.getElementById('cash').innerText = data.cash;
        document.getElementById('bank').innerText = data.bank;
    }
    else if (data.action === 'updateTime') {
        // Update server time (HH:MM)
        document.getElementById('time').innerText = data.time;
    }
});
