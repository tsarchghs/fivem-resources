let isOnJob = false
let jobProgress = 0
let progressInterval

// Listen for messages from the game client
window.addEventListener("message", (event) => {
  const data = event.data

  if (data.type === "openUI") {
    document.getElementById("main-container").classList.add("active")
    document.querySelector(".panel-content").style.opacity = "1"
    document.querySelector(".panel-content").style.transform = "translateY(0)"

    // Update user info
    document.getElementById("username-display").textContent = data.username || "User"

    // Show admin badge if admin
    if (data.isAdmin) {
      document.getElementById("admin-badge").classList.add("visible")
    } else {
      document.getElementById("admin-badge").classList.remove("visible")
    }

    // Update job status
    isOnJob = data.isOnJob
    updateJobStatus()

    if (isOnJob) {
      startJobProgress()
    }
  } else if (data.type === "closeUI") {
    document.getElementById("main-container").classList.remove("active")
    document.querySelector(".panel-content").style.opacity = "0"
    document.querySelector(".panel-content").style.transform = "translateY(30px)"
  } else if (data.type === "notification") {
    showNotification(data.message, data.notificationType)
  } else if (data.type === "jobStarted") {
    isOnJob = true
    updateJobStatus()
    startJobProgress()
  } else if (data.type === "jobEnded") {
    isOnJob = false
    updateJobStatus()
    stopJobProgress()
  }
})

// Update job status display
function updateJobStatus() {
  const statusText = document.getElementById("status-text")
  const startBtn = document.getElementById("start-job-btn")
  const cancelBtn = document.getElementById("cancel-job-btn")

  if (isOnJob) {
    statusText.textContent = "Active"
    statusText.classList.add("active")
    startBtn.disabled = true
    cancelBtn.disabled = false
  } else {
    statusText.textContent = "Not Active"
    statusText.classList.remove("active")
    startBtn.disabled = false
    cancelBtn.disabled = true
    document.getElementById("job-progress").style.width = "0%"
  }
}

// Start job progress animation
function startJobProgress() {
  jobProgress = 0
  const progressBar = document.getElementById("job-progress")

  clearInterval(progressInterval)
  progressInterval = setInterval(() => {
    if (jobProgress < 100) {
      jobProgress += 1
      progressBar.style.width = jobProgress + "%"
    } else {
      clearInterval(progressInterval)
    }
  }, 1000)
}

// Stop job progress animation
function stopJobProgress() {
  clearInterval(progressInterval)
}

// Show notification
function showNotification(message, type = "info") {
  const container = document.getElementById("notification-container")
  const notification = document.createElement("div")
  notification.className = `notification ${type}`
  notification.textContent = message

  container.appendChild(notification)

  setTimeout(() => {
    notification.classList.add("active")
  }, 10)

  setTimeout(() => {
    notification.classList.remove("active")
    setTimeout(() => {
      container.removeChild(notification)
    }, 300)
  }, 5000)
}

// Event listeners
document.addEventListener("DOMContentLoaded", () => {
  console.log('Courier Job UI loaded');
  
  // Start job button
  document.getElementById("start-job-btn").addEventListener("click", () => {
    console.log('Start job button clicked');
    fetch(`https://${GetParentResourceName()}/startCourierJob`, {
      method: "POST",
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({})
    }).catch((error) => {
      console.error('Error in startCourierJob:', error);
    });
  });

  // Cancel job button
  document.getElementById("cancel-job-btn").addEventListener("click", () => {
    console.log('Cancel job button clicked');
    fetch(`https://${GetParentResourceName()}/cancelCourierJob`, {
      method: "POST",
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({})
    }).catch((error) => {
      console.error('Error in cancelCourierJob:', error);
    });
  });

  // Close button
  document.getElementById("close-btn").addEventListener("click", () => {
    console.log('Close button clicked');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
      method: "POST",
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({})
    }).catch((error) => {
      console.error('Error in closeUI:', error);
    });
  });
});

// Close on escape key
document.addEventListener("keyup", (event) => {
  if (event.key === "Escape") {
    console.log('Escape key pressed');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
      method: "POST",
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({})
    }).catch((error) => {
      console.error('Error in closeUI:', error);
    });
  }
});
