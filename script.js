const menu = document.querySelector('.menu');
const navigation = document.querySelector('#navigation');
menu.addEventListener('click', () => {
  const isOpen = menu.getAttribute('aria-expanded') !== 'true';
  menu.setAttribute('aria-expanded', String(isOpen));
  navigation.classList.toggle('open', isOpen);
});
navigation.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
  menu.setAttribute('aria-expanded', 'false');
  navigation.classList.remove('open');
}));
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && menu.getAttribute('aria-expanded') === 'true') {
    menu.setAttribute('aria-expanded', 'false');
    navigation.classList.remove('open');
    menu.focus();
  }
});

const labMembers = [
  'Nilufar Khodzhaeva', 'Sunghyun Ryu', 'Donghyeon Park',
  'Jinkyeong Choi', 'Yejin Noh', 'Donghee Choi',
  'Jaesung Hwang', 'Mogan Gim',
  'Chaebin Jeong', 'Hyeren Yu'
];

document.querySelectorAll('.pub-list li').forEach(item => {
  const walker = document.createTreeWalker(item, NodeFilter.SHOW_TEXT);
  const textNodes = [];
  while (walker.nextNode()) textNodes.push(walker.currentNode);
  textNodes.forEach(node => {
    const parent = node.parentElement;
    if (!parent || parent.closest('a, mark')) return;
    const pattern = new RegExp(`(${labMembers.join('|')})`, 'g');
    if (!pattern.test(node.textContent)) return;
    const fragment = document.createDocumentFragment();
    node.textContent.split(pattern).forEach(part => {
      if (labMembers.includes(part)) {
        const mark = document.createElement('mark');
        mark.className = 'lab';
        mark.textContent = part;
        fragment.append(mark);
      } else {
        fragment.append(document.createTextNode(part));
      }
    });
    node.replaceWith(fragment);
  });
});

document.querySelectorAll('img[src="assets/logo.png"]').forEach((img) => {
  img.addEventListener('error', () => {
    img.src = 'assets/logo.svg';
  }, { once: true });
});

// Team photos: drop a file named <data-photo>.jpg / .jpeg / .png / .webp into
// assets/team/ and it replaces the placeholder automatically.
document.querySelectorAll('.profile img[data-photo]').forEach((img) => {
  const candidates = ['jpg', 'jpeg', 'png', 'webp', 'JPG', 'PNG']
    .map(ext => `assets/team/${img.dataset.photo}.${ext}`);
  const tryNext = () => {
    const src = candidates.shift();
    if (!src) return;
    const probe = new Image();
    probe.onload = () => { img.src = src; img.classList.add('has-photo'); };
    probe.onerror = tryNext;
    probe.src = src;
  };
  tryNext();
});

// Carousels: swipe/scroll track with arrows, dots and a counter.
document.querySelectorAll('[data-carousel]').forEach((carousel) => {
  const track = carousel.querySelector('.carousel-track');
  const slides = [...track.children];
  if (slides.length < 2) return;
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const go = (i) => {
    const index = (i + slides.length) % slides.length;
    track.scrollTo({ left: index * track.clientWidth, behavior: reduce ? 'auto' : 'smooth' });
  };
  const current = () => Math.round(track.scrollLeft / track.clientWidth);
  const button = (cls, label, text, step) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = `carousel-btn ${cls}`;
    b.setAttribute('aria-label', label);
    b.textContent = text;
    b.addEventListener('click', () => go(current() + step));
    carousel.append(b);
  };
  button('prev', 'Previous photo', '‹', -1);
  button('next', 'Next photo', '›', 1);
  const count = document.createElement('span');
  count.className = 'carousel-count';
  const dots = document.createElement('div');
  dots.className = 'carousel-dots';
  slides.forEach((_, i) => {
    const d = document.createElement('button');
    d.type = 'button';
    d.setAttribute('aria-label', `Photo ${i + 1} of ${slides.length}`);
    d.addEventListener('click', () => go(i));
    dots.append(d);
  });
  carousel.append(count, dots);
  const sync = () => {
    const i = current();
    count.textContent = `${i + 1} / ${slides.length}`;
    [...dots.children].forEach((d, k) => d.setAttribute('aria-current', String(k === i)));
  };
  track.addEventListener('scroll', () => requestAnimationFrame(sync), { passive: true });
  window.addEventListener('resize', sync);
  sync();
});
