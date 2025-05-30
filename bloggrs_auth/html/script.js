// Main variables
const notificationQueue = []
let isProcessingNotification = false

// Listen for messages from the game client
window.addEventListener("message", (event) => {
  const data = event.data

  switch (data.type) {
    case "loginSuccess":
      showLoginSuccess(data.username, data.isAdmin)
      break
    case "registerSuccess":
      showRegisterSuccess(data.username)
      break
    case "notification":
      addNotification(data.message, data.notificationType)
      break
    case "showOnlineUsers":
      showOnlineUsers(data.users)
      break
  }
})

// Show login success animation
function showLoginSuccess(username, isAdmin) {
  const container = document.getElementById("login-success")
  const usernameDisplay = container.querySelector(".username-display")
  const progressBar = container.querySelector(".progress")
  const adminBadge = container.querySelector(".admin-badge")

  usernameDisplay.textContent = username

  // Show admin badge if user is admin
  if (isAdmin) {
    adminBadge.classList.add("visible")
  } else {
    adminBadge.classList.remove("visible")
  }

  container.classList.add("active")

  // Animate progress bar
  setTimeout(() => {
    progressBar.style.width = "100%"
  }, 100)

  // Hide after animation completes
  setTimeout(() => {
    container.classList.remove("active")
    setTimeout(() => {
      progressBar.style.width = "0%"
      adminBadge.classList.remove("visible")
    }, 500)
  }, 3500)
}

// Show registration success animation
function showRegisterSuccess(username) {
  const container = document.getElementById("register-success")
  const usernameDisplay = container.querySelector(".username-display")
  const progressBar = container.querySelector(".progress")

  usernameDisplay.textContent = username
  container.classList.add("active")

  // Animate progress bar
  setTimeout(() => {
    progressBar.style.width = "100%"
  }, 100)

  // Hide after animation completes
  setTimeout(() => {
    container.classList.remove("active")
    setTimeout(() => {
      progressBar.style.width = "0%"
    }, 500)
  }, 3500)
}

// Show online users panel (admin only)
function showOnlineUsers(users) {
  const container = document.getElementById("online-users")
  const usersList = container.querySelector(".users-list")
  const panelContent = container.querySelector(".panel-content")
  const closeBtn = container.querySelector(".close-btn")

  // Clear previous users
  usersList.innerHTML = ""

  // Add users to the list
  if (users.length === 0) {
    const emptyMessage = document.createElement("div")
    emptyMessage.className = "empty-message"
    emptyMessage.textContent = "No users online"
    usersList.appendChild(emptyMessage)
  } else {
    users.forEach((user) => {
      const userItem = document.createElement("div")
      userItem.className = "user-item"

      userItem.innerHTML = `
        <div class="user-info">
          <div class="user-name">${user.username}</div>
          <div class="user-id">ID: ${user.id}</div>
        </div>
        <div class="user-time">Login: ${user.loginTime}</div>
      `

      usersList.appendChild(userItem)
    })
  }

  // Show panel
  container.classList.add("active")
  setTimeout(() => {
    panelContent.style.opacity = "1"
    panelContent.style.transform = "translateY(0)"
  }, 100)

  // Close button event
  closeBtn.onclick = () => {
    panelContent.style.opacity = "0"
    panelContent.style.transform = "translateY(30px)"

    setTimeout(() => {
      container.classList.remove("active")
    }, 500)
  }
}

// Add notification to queue
function addNotification(message, type = "info") {
  notificationQueue.push({ message, type })

  if (!isProcessingNotification) {
    processNotificationQueue()
  }
}

// Process notification queue
function processNotificationQueue() {
  if (notificationQueue.length === 0) {
    isProcessingNotification = false
    return
  }

  isProcessingNotification = true
  const { message, type } = notificationQueue.shift()

  // Create notification element
  const notification = document.createElement("div")
  notification.className = `notification ${type}`
  notification.textContent = message

  // Add to container
  const container = document.getElementById("notification-container")
  container.appendChild(notification)

  // Animate in
  setTimeout(() => {
    notification.classList.add("active")
  }, 10)

  // Remove after timeout
  setTimeout(() => {
    notification.classList.remove("active")

    setTimeout(() => {
      notification.remove()
      processNotificationQueue()
    }, 300)
  }, 5000)
}
