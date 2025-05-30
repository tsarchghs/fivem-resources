// Main variables
let playerData = null
let inventory = null
let selectedItem = null
let selectedQuantity = 1
let currentCategory = "all"
let transferType = null
const notificationQueue = []
let isProcessingNotification = false

// Listen for messages from the game client
window.addEventListener("message", (event) => {
  const data = event.data

  switch (data.type) {
    case "openMenu":
      playerData = data.data
      inventory = data.inventory
      openMenu()
      break
    case "closeMenu":
      closeMenu()
      break
    case "updatePlayerData":
      playerData = data.data
      updatePlayerInfo()
      break
    case "updateInventory":
      inventory = data.inventory
      updateInventory()
      break
    case "notification":
      addNotification(data.message, data.notificationType)
      break
    case "loginSuccess":
      showLoginSuccess(data.username, data.isAdmin)
      break
    case "registerSuccess":
      showRegisterSuccess(data.username)
      break
    case "showOnlineUsers":
      showOnlineUsers(data.users)
      break
  }
})

// DOM Elements
document.addEventListener("DOMContentLoaded", () => {
  // Menu elements
  const playerMenu = document.getElementById("player-menu")
  const menuContent = playerMenu.querySelector(".menu-content")
  const closeMenuBtn = document.getElementById("close-menu")

  // Player info elements
  const playerNameElement = document.getElementById("player-name")
  const playerCashElement = document.getElementById("player-cash")
  const playerBankElement = document.getElementById("player-bank")
  const depositBtn = document.getElementById("deposit-btn")
  const withdrawBtn = document.getElementById("withdraw-btn")

  // Inventory elements
  const inventoryWeightElement = document.getElementById("inventory-weight")
  const maxWeightElement = document.getElementById("max-weight")
  const inventoryItemsElement = document.getElementById("inventory-items")
  const categoryButtons = document.querySelectorAll(".category-btn")

  // Item modal elements
  const itemModal = document.getElementById("item-modal")
  const itemModalContent = itemModal.querySelector(".modal-content")
  const closeModalBtn = document.getElementById("close-modal")
  const modalItemName = document.getElementById("modal-item-name")
  const modalItemImg = document.getElementById("modal-item-img")
  const modalItemDescription = document.getElementById("modal-item-description")
  const modalItemWeight = document.getElementById("modal-item-weight")
  const modalItemQuantity = document.getElementById("modal-item-quantity")
  const useItemBtn = document.getElementById("use-item")
  const giveItemBtn = document.getElementById("give-item")
  const dropItemBtn = document.getElementById("drop-item")
  const quantitySelector = document.getElementById("quantity-selector")
  const decreaseQuantityBtn = document.getElementById("decrease-quantity")
  const increaseQuantityBtn = document.getElementById("increase-quantity")
  const quantityInput = document.getElementById("quantity-input")

  // Money modal elements
  const moneyModal = document.getElementById("money-modal")
  const moneyModalContent = moneyModal.querySelector(".modal-content")
  const closeMoneyModalBtn = document.getElementById("close-money-modal")
  const moneyModalTitle = document.getElementById("money-modal-title")
  const moneyModalDescription = document.getElementById("money-modal-description")
  const moneyAmountInput = document.getElementById("money-amount")
  const confirmMoneyTransferBtn = document.getElementById("confirm-money-transfer")
  const cancelMoneyTransferBtn = document.getElementById("cancel-money-transfer")

  // Close menu button
  closeMenuBtn.addEventListener("click", () => {
    fetch("https://player_menu/closeMenu", {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: JSON.stringify({}),
    })
  })

  // Category buttons
  categoryButtons.forEach((button) => {
    button.addEventListener("click", () => {
      // Remove active class from all buttons
      categoryButtons.forEach((btn) => btn.classList.remove("active"))

      // Add active class to clicked button
      button.classList.add("active")

      // Update current category
      currentCategory = button.dataset.category

      // Update inventory display
      updateInventory()
    })
  })

  // Deposit button
  depositBtn.addEventListener("click", () => {
    openMoneyModal("deposit")
  })

  // Withdraw button
  withdrawBtn.addEventListener("click", () => {
    openMoneyModal("withdraw")
  })

  // Close item modal button
  closeModalBtn.addEventListener("click", () => {
    closeItemModal()
  })

  // Use item button
  useItemBtn.addEventListener("click", () => {
    if (selectedItem && selectedItem.data && selectedItem.data.canUse) {
      fetch("https://player_menu/useItem", {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({
          item: selectedItem.id,
        }),
      })

      closeItemModal()
    } else {
      addNotification("This item cannot be used.", "error")
    }
  })

  // Give item button
  giveItemBtn.addEventListener("click", () => {
    if (selectedItem) {
      quantitySelector.classList.add("active")

      // Set max quantity
      quantityInput.max = selectedItem.count

      // Update action buttons
      useItemBtn.style.display = "none"
      giveItemBtn.style.display = "none"
      dropItemBtn.style.display = "none"

      // Add confirm and cancel buttons
      const confirmBtn = document.createElement("button")
      confirmBtn.className = "action-btn"
      confirmBtn.textContent = "Confirm"
      confirmBtn.id = "confirm-give"

      const cancelBtn = document.createElement("button")
      cancelBtn.className = "action-btn"
      cancelBtn.textContent = "Cancel"
      cancelBtn.id = "cancel-action"

      const actionsDiv = document.querySelector(".item-actions")
      actionsDiv.innerHTML = ""
      actionsDiv.appendChild(confirmBtn)
      actionsDiv.appendChild(cancelBtn)

      // Confirm button event
      document.getElementById("confirm-give").addEventListener("click", () => {
        const quantity = Number.parseInt(quantityInput.value)

        if (quantity > 0 && quantity <= selectedItem.count) {
          fetch("https://player_menu/giveItem", {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({
              item: selectedItem.id,
              count: quantity,
            }),
          })

          closeItemModal()
        } else {
          addNotification("Invalid quantity.", "error")
        }
      })

      // Cancel button event
      document.getElementById("cancel-action").addEventListener("click", () => {
        closeItemModal()
      })
    }
  })

  // Drop item button
  dropItemBtn.addEventListener("click", () => {
    if (selectedItem) {
      quantitySelector.classList.add("active")

      // Set max quantity
      quantityInput.max = selectedItem.count

      // Update action buttons
      useItemBtn.style.display = "none"
      giveItemBtn.style.display = "none"
      dropItemBtn.style.display = "none"

      // Add confirm and cancel buttons
      const confirmBtn = document.createElement("button")
      confirmBtn.className = "action-btn"
      confirmBtn.textContent = "Confirm"
      confirmBtn.id = "confirm-drop"

      const cancelBtn = document.createElement("button")
      cancelBtn.className = "action-btn"
      cancelBtn.textContent = "Cancel"
      cancelBtn.id = "cancel-action"

      const actionsDiv = document.querySelector(".item-actions")
      actionsDiv.innerHTML = ""
      actionsDiv.appendChild(confirmBtn)
      actionsDiv.appendChild(cancelBtn)

      // Confirm button event
      document.getElementById("confirm-drop").addEventListener("click", () => {
        const quantity = Number.parseInt(quantityInput.value)

        if (quantity > 0 && quantity <= selectedItem.count) {
          fetch("https://player_menu/dropItem", {
            method: "POST",
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({
              item: selectedItem.id,
              count: quantity,
            }),
          })

          closeItemModal()
        } else {
          addNotification("Invalid quantity.", "error")
        }
      })

      // Cancel button event
      document.getElementById("cancel-action").addEventListener("click", () => {
        closeItemModal()
      })
    }
  })

  // Quantity selector buttons
  decreaseQuantityBtn.addEventListener("click", () => {
    const quantity = Number.parseInt(quantityInput.value)
    if (quantity > 1) {
      quantityInput.value = quantity - 1
    }
  })

  increaseQuantityBtn.addEventListener("click", () => {
    const quantity = Number.parseInt(quantityInput.value)
    const maxQuantity = Number.parseInt(quantityInput.max)
    if (quantity < maxQuantity) {
      quantityInput.value = quantity + 1
    }
  })

  // Close money modal button
  closeMoneyModalBtn.addEventListener("click", () => {
    closeMoneyModal()
  })

  // Confirm money transfer button
  confirmMoneyTransferBtn.addEventListener("click", () => {
    const amount = Number.parseInt(moneyAmountInput.value)

    if (amount <= 0) {
      addNotification("Amount must be greater than 0.", "error")
      return
    }

    if (transferType === "deposit") {
      // Check if player has enough cash
      if (playerData.cash < amount) {
        addNotification("Not enough cash.", "error")
        return
      }

      fetch("https://player_menu/transferMoney", {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({
          from: "cash",
          to: "bank",
          amount: amount,
        }),
      })
    } else if (transferType === "withdraw") {
      // Check if player has enough bank money
      if (playerData.bank < amount) {
        addNotification("Not enough money in bank.", "error")
        return
      }

      fetch("https://player_menu/transferMoney", {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({
          from: "bank",
          to: "cash",
          amount: amount,
        }),
      })
    }

    closeMoneyModal()
  })

  // Cancel money transfer button
  cancelMoneyTransferBtn.addEventListener("click", () => {
    closeMoneyModal()
  })

  // Close modals when clicking outside
  window.addEventListener("click", (event) => {
    if (event.target === itemModal) {
      closeItemModal()
    }

    if (event.target === moneyModal) {
      closeMoneyModal()
    }
  })
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

// Open menu
function openMenu() {
  const playerMenu = document.getElementById("player-menu")
  const menuContent = playerMenu.querySelector(".menu-content")

  playerMenu.classList.add("active")

  setTimeout(() => {
    menuContent.style.opacity = "1"
    menuContent.style.transform = "translateY(0)"

    // Update player info and inventory
    updatePlayerInfo()
    updateInventory()
  }, 100)
}

// Close menu
function closeMenu() {
  const playerMenu = document.getElementById("player-menu")
  const menuContent = playerMenu.querySelector(".menu-content")

  menuContent.style.opacity = "0"
  menuContent.style.transform = "translateY(30px)"

  setTimeout(() => {
    playerMenu.classList.remove("active")
  }, 500)
}

// Update player info
function updatePlayerInfo() {
  if (!playerData) return

  const playerNameElement = document.getElementById("player-name")
  const playerCashElement = document.getElementById("player-cash")
  const playerBankElement = document.getElementById("player-bank")

  playerNameElement.textContent = playerData.username || "Unknown"
  playerCashElement.textContent = playerData.cash.toLocaleString() || "0"
  playerBankElement.textContent = playerData.bank.toLocaleString() || "0"
}

// Update inventory
function updateInventory() {
  const inventoryItemsElement = document.getElementById("inventory-items")
  const inventoryWeightElement = document.getElementById("inventory-weight")
  const maxWeightElement = document.getElementById("max-weight")
  
  // Clear current items
  inventoryItemsElement.innerHTML = ""
  
  // Calculate total weight
  let totalWeight = 0
  let maxWeight = 30.0 // This should match Config.MaxInventoryWeight
  
  if (inventory) {
    // Sort items by name
    const sortedItems = Object.entries(inventory).sort((a, b) => {
      return a[1].label.localeCompare(b[1].label)
    })
    
    // Display items
    for (const [itemId, itemData] of sortedItems) {
      // Calculate item weight (0.1 per item)
      const itemWeight = 0.1 * itemData.count
      totalWeight += itemWeight
      
      // Create item element
      const itemElement = document.createElement("div")
      itemElement.className = "inventory-item"
      itemElement.dataset.item = itemId
      
      // Add item content
      itemElement.innerHTML = `
        <div class="item-img">
          <img src="img/items/${itemId}.png" onerror="this.src='img/items/default.png'" alt="${itemData.label}">
          <span class="item-count">${itemData.count}</span>
        </div>
        <div class="item-info">
          <div class="item-name">${itemData.label}</div>
          <div class="item-weight">${itemWeight.toFixed(1)} kg</div>
        </div>
      `
      
      // Add click event
      itemElement.addEventListener("click", () => {
        openItemModal({
          id: itemId,
          ...itemData
        })
      })
      
      // Add to container
      inventoryItemsElement.appendChild(itemElement)
    }
  }
  
  // Update weight display
  inventoryWeightElement.textContent = totalWeight.toFixed(1)
  maxWeightElement.textContent = maxWeight.toFixed(1)
}

// Open item modal
function openItemModal(item) {
  selectedItem = item
  const itemModal = document.getElementById("item-modal")
  const modalItemName = document.getElementById("modal-item-name")
  const modalItemImg = document.getElementById("modal-item-img")
  const modalItemDescription = document.getElementById("modal-item-description")
  const modalItemWeight = document.getElementById("modal-item-weight")
  const modalItemQuantity = document.getElementById("modal-item-quantity")
  const useItemBtn = document.getElementById("use-item")
  const quantitySelector = document.getElementById("quantity-selector")
  
  // Calculate weight
  const itemWeight = 0.1 * item.count
  
  // Set modal content
  modalItemName.textContent = item.label
  modalItemImg.src = `img/items/${item.id}.png`
  modalItemImg.onerror = () => modalItemImg.src = "img/items/default.png"
  modalItemDescription.textContent = item.data.description || "No description available."
  modalItemWeight.textContent = `${itemWeight.toFixed(1)} kg`
  modalItemQuantity.textContent = item.count
  
  // Show/hide use button based on item type
  useItemBtn.style.display = "block"
  
  // Reset quantity selector
  const quantityInput = document.getElementById("quantity-input")
  quantityInput.value = 1
  quantityInput.max = item.count
  quantitySelector.classList.remove("active")
  
  // Show modal
  itemModal.classList.add("active")
}

// Close item modal
function closeItemModal() {
  const itemModal = document.getElementById("item-modal")
  const modalContent = itemModal.querySelector(".modal-content")

  modalContent.style.opacity = "0"
  modalContent.style.transform = "translateY(20px)"

  setTimeout(() => {
    itemModal.classList.remove("active")
    selectedItem = null
  }, 300)
}

// Open money modal
function openMoneyModal(type) {
  const moneyModal = document.getElementById("money-modal")
  const modalContent = moneyModal.querySelector(".modal-content")
  const moneyModalTitle = document.getElementById("money-modal-title")
  const moneyModalDescription = document.getElementById("money-modal-description")
  const moneyAmountInput = document.getElementById("money-amount")

  // Store transfer type
  transferType = type

  // Update modal content
  if (type === "deposit") {
    moneyModalTitle.textContent = "Deposit Money"
    moneyModalDescription.textContent = "Transfer money from cash to bank."
    moneyAmountInput.max = playerData.cash
    moneyAmountInput.value = Math.min(100, playerData.cash)
  } else if (type === "withdraw") {
    moneyModalTitle.textContent = "Withdraw Money"
    moneyModalDescription.textContent = "Transfer money from bank to cash."
    moneyAmountInput.max = playerData.bank
    moneyAmountInput.value = Math.min(100, playerData.bank)
  }

  // Show modal
  moneyModal.classList.add("active")
  setTimeout(() => {
    modalContent.style.opacity = "1"
    modalContent.style.transform = "translateY(0)"
  }, 100)
}

// Close money modal
function closeMoneyModal() {
  const moneyModal = document.getElementById("money-modal")
  const modalContent = moneyModal.querySelector(".modal-content")

  modalContent.style.opacity = "0"
  modalContent.style.transform = "translateY(20px)"

  setTimeout(() => {
    moneyModal.classList.remove("active")
    transferType = null
  }, 300)
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
