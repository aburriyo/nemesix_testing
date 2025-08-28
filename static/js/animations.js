// Animaciones con Anime.js para NemesixWeb

document.addEventListener('DOMContentLoaded', function() {
    
    // ===== ANIMACIONES DE CARGA =====
    function initLoadingAnimation() {
        // Crear overlay de carga
        const loadingOverlay = document.createElement('div');
        loadingOverlay.className = 'loading-overlay';
        loadingOverlay.innerHTML = '<div class="loading-spinner"></div>';
        document.body.appendChild(loadingOverlay);

        // Animar spinner
        anime({
            targets: '.loading-spinner',
            rotate: '1turn',
            duration: 1000,
            loop: true,
            easing: 'linear'
        });

        // Ocultar loading después de que cargue la página
        window.addEventListener('load', function() {
            anime({
                targets: '.loading-overlay',
                opacity: 0,
                duration: 500,
                easing: 'easeOutQuad',
                complete: function() {
                    loadingOverlay.remove();
                    initPageAnimations();
                }
            });
        });
    }

    // ===== ANIMACIONES PRINCIPALES =====
    function initPageAnimations() {
        
        // Animación del logo de navegación
        anime({
            targets: '.animate-logo',
            opacity: [0, 1],
            translateX: [-30, 0],
            duration: 800,
            delay: 200,
            easing: 'easeOutCubic'
        });

        // Animación de elementos de navegación
        anime({
            targets: '.animate-nav-items .nav-item',
            opacity: [0, 1],
            translateY: [-20, 0],
            duration: 600,
            delay: anime.stagger(100, {start: 400}),
            easing: 'easeOutCubic'
        });

        // Animación del contenido hero
        anime({
            targets: '.hero-content',
            opacity: [0, 1],
            translateY: [50, 0],
            duration: 1000,
            delay: 600,
            easing: 'easeOutCubic'
        });

        // Animación de títulos con efecto de escritura
        animateTypewriter('.hero-title', 100);
    }

    // ===== SCROLL ANIMATIONS =====
    function initScrollAnimations() {
        
        // Barra de progreso de scroll
        const scrollIndicator = document.createElement('div');
        scrollIndicator.className = 'scroll-indicator';
        document.body.appendChild(scrollIndicator);

        window.addEventListener('scroll', function() {
            const scrollPercent = (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100;
            
            anime({
                targets: '.scroll-indicator',
                scaleX: scrollPercent / 100,
                duration: 100,
                easing: 'linear'
            });

            // Navbar scroll effect
            const navbar = document.getElementById('mainNav');
            if (window.scrollY > 50) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
        });

        // Intersection Observer para animaciones al hacer scroll
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    animateOnScroll(entry.target);
                }
            });
        }, observerOptions);

        // Observar elementos que se deben animar
        document.querySelectorAll('.animate-card, .team-member, .game-info').forEach(el => {
            observer.observe(el);
        });
    }

    // ===== ANIMACIONES ESPECÍFICAS =====
    function animateOnScroll(element) {
        if (element.classList.contains('animate-card')) {
            anime({
                targets: element,
                opacity: [0, 1],
                translateY: [50, 0],
                scale: [0.9, 1],
                duration: 800,
                easing: 'easeOutCubic'
            });
        }

        if (element.classList.contains('team-member')) {
            anime({
                targets: element,
                opacity: [0, 1],
                translateY: [30, 0],
                duration: 600,
                easing: 'easeOutCubic'
            });
        }

        if (element.classList.contains('game-info')) {
            anime({
                targets: element,
                opacity: [0, 1],
                translateX: [-50, 0],
                duration: 800,
                easing: 'easeOutCubic'
            });
        }
    }

    // Efecto de escritura para títulos
    function animateTypewriter(selector, speed = 50) {
        const element = document.querySelector(selector);
        if (!element) return;

        const text = element.textContent;
        element.textContent = '';
        element.style.opacity = '1';

        let i = 0;
        const timer = setInterval(() => {
            if (i < text.length) {
                element.textContent += text.charAt(i);
                i++;
            } else {
                clearInterval(timer);
            }
        }, speed);
    }

    // ===== EFECTOS DE HOVER =====
    function initHoverEffects() {
        // Efecto hover para botones
        document.querySelectorAll('.btn-animated').forEach(btn => {
            btn.addEventListener('mouseenter', function() {
                anime({
                    targets: this,
                    scale: 1.05,
                    duration: 200,
                    easing: 'easeOutQuad'
                });
            });

            btn.addEventListener('mouseleave', function() {
                anime({
                    targets: this,
                    scale: 1,
                    duration: 200,
                    easing: 'easeOutQuad'
                });
            });
        });

        // Efecto hover para cards
        document.querySelectorAll('.animate-card').forEach(card => {
            card.addEventListener('mouseenter', function() {
                anime({
                    targets: this,
                    translateY: -10,
                    scale: 1.02,
                    duration: 300,
                    easing: 'easeOutCubic'
                });
            });

            card.addEventListener('mouseleave', function() {
                anime({
                    targets: this,
                    translateY: 0,
                    scale: 1,
                    duration: 300,
                    easing: 'easeOutCubic'
                });
            });
        });
    }

    // ===== SMOOTH SCROLL =====
    function initSmoothScroll() {
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function(e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                
                if (target) {
                    anime({
                        targets: 'html, body',
                        scrollTop: target.offsetTop - 80,
                        duration: 1000,
                        easing: 'easeInOutCubic'
                    });
                }
            });
        });
    }

    // ===== EFECTOS DE PARTÍCULAS =====
    function createFloatingParticles() {
        const particleCount = 20;
        const container = document.body;

        for (let i = 0; i < particleCount; i++) {
            const particle = document.createElement('div');
            particle.className = 'floating-particle';
            particle.style.cssText = `
                position: fixed;
                width: 4px;
                height: 4px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                pointer-events: none;
                z-index: -1;
            `;
            
            container.appendChild(particle);
            
            anime({
                targets: particle,
                translateX: function() {
                    return anime.random(-200, window.innerWidth + 200);
                },
                translateY: function() {
                    return anime.random(-200, window.innerHeight + 200);
                },
                opacity: [0, 1, 0],
                scale: [0, 1, 0],
                duration: function() {
                    return anime.random(3000, 6000);
                },
                delay: function() {
                    return anime.random(0, 2000);
                },
                loop: true,
                easing: 'easeInOutSine'
            });
        }
    }

    // ===== INICIALIZACIÓN =====
    initLoadingAnimation();
    initScrollAnimations();
    initHoverEffects();
    initSmoothScroll();
    createFloatingParticles();

    // Mensaje de consola para desarrolladores
    console.log('🎮 Nemesix Web - Animaciones cargadas correctamente');
    console.log('✨ Powered by Anime.js');
});