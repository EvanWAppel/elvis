'use strict';
const layers = {
  culture: { kicker: 'The city as a canvas', title: 'Look a little<br>closer.', description: 'Public art, neighborhood parks, and the places that give the valley its character.', link: 'Explore public art', path: 'public_art', color: '#bd3c24', points: [[42,24],[47,31],[52,40],[38,39],[58,30],[64,45],[47,48],[42,58],[55,57],[50,72],[62,65],[73,70],[36,52],[60,20],[54,82],[33,30],[69,55],[45,67]] },
  civic: { kicker: 'Behind the everyday', title: 'A city<br>at work.', description: 'Restaurant inspections, building permits, and the businesses that keep the valley moving.', link: 'Explore inspections', path: 'restaurants', color: '#46583d', points: [[41,20],[48,28],[52,34],[46,40],[40,45],[50,53],[56,60],[65,68],[60,43],[71,64],[48,68],[36,60],[55,25],[67,36],[75,76],[43,76],[59,75],[32,42]] },
  desert: { kicker: 'Life at the extremes', title: 'The landscape<br>is changing.', description: 'Lake Mead’s water levels, extreme heat, and air quality reveal the valley’s relationship with the desert.', link: 'Explore Lake Mead', path: 'lake_mead', color: '#75613c', points: [[19,25],[23,47],[30,68],[47,76],[72,29],[79,47],[83,66],[71,78],[62,15],[45,15],[33,22],[58,84]] }
};
const points = document.getElementById('map-points');
for (let i = 0; i < 18; i++) { const point = document.createElement('i'); point.className = 'map-point'; points.append(point); }
function selectLayer(name) {
  const layer = layers[name];
  document.querySelectorAll('[data-layer]').forEach(button => { const selected = button.dataset.layer === name; button.classList.toggle('active', selected); button.setAttribute('aria-pressed', String(selected)); });
  document.getElementById('layer-kicker').textContent = layer.kicker;
  document.getElementById('layer-title').innerHTML = layer.title;
  document.getElementById('layer-description').textContent = layer.description;
  const link = document.getElementById('layer-link'); link.textContent = layer.link + ' ↗'; link.href = 'https://elvis-production-e07a.up.railway.app/' + layer.path;
  [...points.children].forEach((point, i) => { const position = layer.points[i]; point.hidden = !position; if (position) { point.style.left = position[0] + '%'; point.style.top = position[1] + '%'; point.style.background = layer.color; } });
}
document.querySelectorAll('[data-layer]').forEach(button => button.addEventListener('click', () => selectLayer(button.dataset.layer)));
selectLayer('culture');
