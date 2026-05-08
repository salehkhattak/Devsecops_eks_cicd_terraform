document.addEventListener('DOMContentLoaded', () => {
    const messageForm = document.getElementById('messageForm');
    
    if(messageForm) {
        messageForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const submitBtn = this.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.textContent = 'Posting...';
            submitBtn.disabled = true;

            const formData = new FormData(this);
            
            fetch('/submit', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.message) {
                    showToast('Message posted successfully!', 'success');
                    this.reset();
                    // Reload page to show new message smoothly
                    setTimeout(() => {
                        location.reload();
                    }, 800);
                } else if (data.error) {
                    showToast(`Error: ${data.error}`, 'error');
                }
            })
            .catch(error => {
                showToast(`Network Error: ${error}`, 'error');
            })
            .finally(() => {
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            });
        });
    }

    // Like functionality
    const likeButtons = document.querySelectorAll('.like-btn');
    likeButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const messageId = this.getAttribute('data-id');
            const likeCountSpan = this.querySelector('.like-count');
            const icon = this.querySelector('i');
            
            // Prevent multiple clicks
            if(this.classList.contains('liked')) return;

            fetch(`/like/${messageId}`, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.message) {
                    // Update UI immediately for better UX
                    let currentCount = parseInt(likeCountSpan.textContent);
                    likeCountSpan.textContent = currentCount + 1;
                    
                    this.classList.add('liked');
                    icon.classList.remove('far');
                    icon.classList.add('fas');
                    
                    // Small pop animation
                    icon.style.transform = 'scale(1.4)';
                    setTimeout(() => icon.style.transform = '', 200);
                }
            })
            .catch(err => console.error("Error liking message", err));
        });
    });
});

// Toast notification system
function showToast(message, type = 'success') {
    let container = document.getElementById('toast-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toast-container';
        document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    // Icon based on type
    const iconClass = type === 'success' ? 'fas fa-check-circle' : 'fas fa-exclamation-circle';
    const iconColor = type === 'success' ? 'var(--success)' : 'var(--error)';
    
    toast.innerHTML = `
        <i class="${iconClass}" style="color: ${iconColor}; font-size: 1.2rem;"></i>
        <span>${message}</span>
    `;
    
    container.appendChild(toast);
    
    // Remove toast after animation finishes (3.3s total)
    setTimeout(() => {
        toast.remove();
    }, 3500);
}
