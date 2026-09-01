# LEMR Community Housing Acquisition Tool landing page

This folder contains a one-page Quarto site and web-optimized demo media. The original recordings remain in the project root and are ignored by Git so that the GitHub repository only receives the small, edited loops under `assets/media/`.

## Preview locally

1. Install [Quarto](https://quarto.org/docs/get-started/).
2. From this folder, run `quarto preview`.
3. Edit the page copy in `index.qmd` and the presentation in `assets/css/styles.css`.

## Publish with GitHub Pages

1. Create a GitHub repository and push this folder to its `main` branch.
2. In the repository, open **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to **GitHub Actions**.
4. The included workflow will render and deploy the site after every push to `main`.
5. Once the repository URL is final, add it as `website.site-url` in `_quarto.yml` so Quarto emits an absolute social-preview image URL.

## Re-process the recordings

The edit decisions are documented in `scripts/process-videos.ps1`. It removes long loading periods, accelerates the useful interaction sequences, exports 1280-pixel-wide H.264 loops, and creates poster images. The checked-in optimized videos are ready to use; re-processing is only necessary if the originals change.
