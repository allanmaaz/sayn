import { useEffect, useState } from 'react';

export function useScrollAnimation() {
  const [scrollProgress, setScrollProgress] = useState(0);
  const [scrollY, setScrollY] = useState(0);

  useEffect(() => {
    let ticking = false;

    const handleScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          const currentY = window.scrollY || window.pageYOffset;
          setScrollY(currentY);

          const totalHeight = document.documentElement.scrollHeight - window.innerHeight;
          if (totalHeight > 0) {
            const progress = Math.min(100, Math.max(0, (currentY / totalHeight) * 100));
            setScrollProgress(progress);
          }
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll();

    // Check for native CSS scroll-timeline support
    const hasCssScroll =
      typeof window !== 'undefined' &&
      window.CSS &&
      CSS.supports &&
      CSS.supports('(animation-timeline: view()) and (animation-range: entry)');

    const elements = document.querySelectorAll('.reveal-on-scroll');
    if (elements.length > 0) {
      if (hasCssScroll) {
        // On browsers with native CSS scroll-timeline, immediately set revealed so no FOUC
        elements.forEach((el) => el.classList.add('is-revealed'));
      } else {
        // High-performance IntersectionObserver for cross-browser fallback
        const observer = new IntersectionObserver(
          (entries) => {
            entries.forEach((entry) => {
              if (entry.isIntersecting) {
                entry.target.classList.add('is-revealed');
              }
            });
          },
          {
            threshold: 0.1,
            rootMargin: '0px 0px -40px 0px',
          }
        );

        elements.forEach((el) => observer.observe(el));

        return () => {
          window.removeEventListener('scroll', handleScroll);
          observer.disconnect();
        };
      }
    }

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  return { scrollProgress, scrollY };
}
