window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'showUI':
            document.getElementById('zoneInfo').classList.remove('hidden');
            updateInfo(data.data);
            break;
            
        case 'hideUI':
            document.getElementById('zoneInfo').classList.add('hidden');
            document.getElementById('noclipInfo').classList.add('hidden');
            break;
            
        case 'updateZoneInfo':
            updateInfo(data.data);
            break;
            
        case 'updateNoclip':
            updateNoclip(data);
            break;
    }
});

function updateInfo(data) {
    document.getElementById('pointCount').textContent = data.points;
    document.getElementById('area').textContent = data.area.toLocaleString() + ' m²';
    document.getElementById('perimeter').textContent = data.perimeter.toLocaleString() + ' m';
}

function updateNoclip(data) {
    const noclipInfo = document.getElementById('noclipInfo');
    if (data.active) {
        noclipInfo.classList.remove('hidden');
        document.getElementById('speed').textContent = data.speed;
    } else {
        noclipInfo.classList.add('hidden');
    }
}