<template>
  <div class="px-4 py-8 flex flex-col items-center justify-center bg-neon">
    <h1 class="text-neon">
      AIFIRE
    </h1>
  </div>
</template>

<style scoped>
.bg-neon {
  --neon-from: #00f3ff;
  --neon-to: #fb3fff;
  --neon-bg: #000;
  position: relative;
  border-radius: 8px;
  background: linear-gradient(var(--neon-bg), var(--neon-bg)) padding-box,
              linear-gradient(90deg, var(--neon-from), var(--neon-to)) border-box;
  border: 2px solid transparent;
  box-shadow:
    0 0 10px color-mix(in srgb, var(--neon-from) 50%, transparent),
    0 0 20px color-mix(in srgb, var(--neon-to) 50%, transparent);
}

.text-neon {
  --neon-text-light: rgba(255,255,255, .25);
  --neon-text-color: #bf3fff;
  --neon-from: #00f3ff;
  --neon-to: #fb3fff;
  position: relative;
  z-index: 2;
  padding-bottom: 0.1em;
  color: #FEFCFF;
  font-size: 3em;
  font-family: 'Jura', sans-serif;
  line-height: 1;
  text-shadow:
    -0.2rem -0.2rem 1rem var(--neon-text-light),
    0.2rem 0.2rem 1rem var(--neon-text-light),
    0 0 2rem var(--neon-text-color),
    0 0 4rem var(--neon-text-color),
    0 0 6rem var(--neon-text-color),
    0 0 8rem var(--neon-text-color),
    0 0 10rem var(--neon-text-color);
  &:before {
    content: "";
    position: absolute;
    inset: 0;
    margin: auto;
    display: block;
    z-index: -1;
    height: 180%;
    aspect-ratio: 1 / 1;
    border-radius: 50%;
    border: 2px solid transparent;
    background: linear-gradient(var(--neon-bg), var(--neon-bg)) padding-box,
                linear-gradient(90deg, var(--neon-from), var(--neon-to)) border-box;
    box-shadow:
      0 0 10px color-mix(in srgb, var(--neon-from) 50%, transparent),
      0 0 20px color-mix(in srgb, var(--neon-to) 50%, transparent);
    animation: neonGlow 1.5s ease-in-out infinite alternate, neonRotate 4s linear infinite;
  }
}

@keyframes neonGlow {
  from {
    box-shadow:
      0 0 10px rgba(0, 243, 255, 0.5),
      0 0 20px rgba(251, 63, 255, 0.5);
  }
  to {
    box-shadow:
      0 0 20px rgba(0, 243, 255, 0.8),
      0 0 40px rgba(251, 63, 255, 0.8);
  }
}

@keyframes neonRotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
