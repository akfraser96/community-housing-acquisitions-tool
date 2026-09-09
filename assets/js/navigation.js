(() => {
  const menu = document.querySelector('.page-menu');
  if (!menu) return;

  menu.addEventListener('click', (event) => {
    if (event.target.closest('a[href^="#"]')) menu.open = false;
  });

  document.addEventListener('click', (event) => {
    if (!menu.contains(event.target)) menu.open = false;
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && menu.open) {
      menu.open = false;
      menu.querySelector('summary').focus();
    }
  });
})();
