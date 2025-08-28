// === Ocultar/Mostrar la barra de navegación al hacer scroll ===
let nav = document.getElementById("nav");
let lastScrollTop = 0;

window.addEventListener("scroll", function () {
  let scrollTop = window.scrollY || document.documentElement.scrollTop;

  if (scrollTop > lastScrollTop) {
    nav.style.top = "-100px"; // Ajusta esto a la altura de tu nav
  } else {
    nav.style.top = "0";
  }

  lastScrollTop = scrollTop;
});




//VIDEO TEASER!!!

document.addEventListener('DOMContentLoaded', () => {
  const header = document.getElementById('intro');
  const video = document.getElementById('introVideo');

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      header.innerHTML = '';
      video.style.display = 'block';
      video.play();
    }
  });
});





document.addEventListener('DOMContentLoaded', () => {
    const navSelector = document.getElementById("nav-selector");
    if (navSelector) {
        navSelector.addEventListener("change", function () {
            const destino = this.value;
            if (destino) {
                // Redirige a la sección dentro de la misma página
                window.location.hash = destino;
            }
        });
    }
});





// === IntersectionObserver para textos e imágenes que aparecen con scroll ===
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const el = entry.target;

      // Textos
      if (el.classList.contains('descripcion-izq')) {
        el.classList.add('scroll-activo-izq');
      }
      if (el.classList.contains('descripcion-der')) {
        el.classList.add('scroll-activo-der');
      }

      // Imágenes (desde el lado contrario)
      if (el.classList.contains('img-izq')) {
        el.classList.add('scroll-activo-img-izq');
      }
      if (el.classList.contains('img-der')) {
        el.classList.add('scroll-activo-img-der');
      }
    }
  });
}, {
  threshold: 0.1
});

// Observar textos e imágenes
document.querySelectorAll('.descripcion-izq, .descripcion-der, .img-izq, .img-der')
  .forEach(el => observer.observe(el));








document.addEventListener('DOMContentLoaded', function() {
    const scrollToTopButton = document.getElementById('scrollToTop');

    // Mostrar el botón cuando el usuario se desplaza hacia abajo
    window.addEventListener('scroll', function() {
        if (window.scrollY > 300) { // Mostrar el botón después de desplazarse 300px
            scrollToTopButton.style.display = 'block';
        } else {
            scrollToTopButton.style.display = 'none';
        }
    });

    // Desplazarse al principio de la página cuando se hace clic en el botón
    scrollToTopButton.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
});







// === Mostrar/Ocultar cajas de información ===
function hideAll(callback) {
  const boxes = document.querySelectorAll('.info-box');
  let boxesToHide = 0;

  boxes.forEach(box => {
    if (box.classList.contains('active')) {
      boxesToHide++;
      box.classList.remove('active');
      setTimeout(() => {
        box.style.display = 'none';
        boxesToHide--;
        if (boxesToHide === 0 && typeof callback === 'function') {
          callback();
        }
      }, 500); // igual a la duración de la transición
    }
  });

  if (boxesToHide === 0 && typeof callback === 'function') {
    callback();
  }

  document.getElementById('avatars-container').style.display = 'none';
}

function showInfoBox(id) {
  hideAll(() => {
    const box = document.getElementById('info-' + id);
    if (box) {
      box.style.display = 'block';
      setTimeout(() => {
        box.classList.add('active');
      }, 10);
    }
  });
}

function returnToAvatars() {
  hideAll(() => {
    document.getElementById('avatars-container').style.display = 'flex';
  });
}


// Auto-ocultar mensajes flash después de 5 segundos
document.addEventListener('DOMContentLoaded', function() {
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(function(alert) {
        setTimeout(function() {
            alert.style.opacity = '0';
            setTimeout(function() {
                alert.remove();
            }, 300);
        }, 5000);
    });
});

// Validación de formularios en tiempo real mejorada
function validateForm(formSelector) {
    const form = document.querySelector(formSelector);
    if (!form) return;

    const inputs = form.querySelectorAll('input[required]');

    inputs.forEach(input => {
        input.addEventListener('blur', function() {
            validateField(this);
        });

        input.addEventListener('input', function() {
            // Limpiar errores mientras el usuario escribe
            const existingError = this.parentNode.querySelector('.field-error');
            if (existingError) {
                existingError.remove();
            }
            this.classList.remove('invalid', 'valid');
        });
    });

    // Validación al enviar el formulario
    form.addEventListener('submit', function(e) {
        let isValidForm = true;
        inputs.forEach(input => {
            if (!validateField(input)) {
                isValidForm = false;
            }
        });

        if (!isValidForm) {
            e.preventDefault();
        }
    });
}

function validateField(field) {
    const value = field.value.trim();
    const fieldName = field.name;

    // Remover errores previos
    const existingError = field.parentNode.querySelector('.field-error');
    if (existingError) existingError.remove();

    let isValid = true;
    let errorMessage = '';

    if (value === '') {
        isValid = false;
        errorMessage = 'Este campo es requerido';
    } else {
        switch (fieldName) {
            case 'email':
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(value)) {
                    isValid = false;
                    errorMessage = 'Ingrese un email válido';
                }
                break;
            case 'username':
                if (value.length < 3) {
                    isValid = false;
                    errorMessage = 'El nombre de usuario debe tener al menos 3 caracteres';
                } else if (!/^[a-zA-Z0-9_]+$/.test(value)) {
                    isValid = false;
                    errorMessage = 'Solo se permiten letras, números y guiones bajos';
                }
                break;
            case 'password':
                if (value.length < 6) {
                    isValid = false;
                    errorMessage = 'La contraseña debe tener al menos 6 caracteres';
                }
                break;
        }
    }

    if (!isValid) {
        field.classList.add('invalid');
        field.classList.remove('valid');
        const errorDiv = document.createElement('div');
        errorDiv.className = 'field-error';
        errorDiv.textContent = errorMessage;
        field.parentNode.appendChild(errorDiv);
    } else {
        field.classList.add('valid');
        field.classList.remove('invalid');
    }

    return isValid;
}

// Inicializar validaciones cuando se cargan los formularios
document.addEventListener('DOMContentLoaded', function() {
    // Navegación
    const navSelector = document.getElementById("nav-selector");
    if (navSelector) {
        navSelector.addEventListener("change", function () {
            const destino = this.value;
            if (destino) {
                window.location.hash = destino;
            }
        });
    }

    // Validación de formularios
    validateForm('.styled-form');
    validateForm('form[action="/login"]');
    validateForm('form[action="/register"]');
    
    // Auto-ocultar mensajes flash
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(function(alert) {
        setTimeout(function() {
            alert.style.opacity = '0';
            setTimeout(function() {
                if (alert.parentNode) {
                    alert.remove();
                }
            }, 300);
        }, 5000);
    });

    // Scroll to top button
    const scrollToTopButton = document.getElementById('scrollToTop');
    if (scrollToTopButton) {
        window.addEventListener('scroll', function() {
            if (window.scrollY > 300) {
                scrollToTopButton.style.display = 'block';
            } else {
                scrollToTopButton.style.display = 'none';
            }
        });

        scrollToTopButton.addEventListener('click', function() {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }
});
