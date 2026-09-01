(() => {
  const videos = [...document.querySelectorAll(".demo-video")];
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  const setButton = (video, playing) => {
    const button = video.closest(".video-shell")?.querySelector(".video-control");
    if (!button) return;

    button.dataset.state = playing ? "playing" : "paused";
    button.setAttribute("aria-label", `${playing ? "Pause" : "Play"} ${video.getAttribute("aria-label") || "demonstration"}`);
    button.querySelector("span").textContent = playing ? "Ⅱ" : "▶";
  };

  const playVideo = async (video) => {
    if (reduceMotion.matches) {
      setButton(video, false);
      return;
    }

    try {
      await video.play();
      setButton(video, true);
    } catch {
      setButton(video, false);
    }
  };

  videos.forEach((video) => {
    const button = video.closest(".video-shell")?.querySelector(".video-control");
    setButton(video, false);

    button?.addEventListener("click", () => {
      if (video.paused) {
        playVideo(video);
      } else {
        video.pause();
        setButton(video, false);
      }
    });

    video.addEventListener("play", () => setButton(video, true));
    video.addEventListener("pause", () => setButton(video, false));
  });

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const video = entry.target;
        if (entry.isIntersecting && entry.intersectionRatio >= 0.35) {
          playVideo(video);
        } else {
          video.pause();
        }
      });
    },
    { threshold: [0, 0.35, 0.7] }
  );

  videos.forEach((video) => observer.observe(video));

  reduceMotion.addEventListener("change", () => {
    if (reduceMotion.matches) videos.forEach((video) => video.pause());
  });
})();
