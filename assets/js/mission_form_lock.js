const MissionFormLock = {
  mounted() {
    this.pending = false
    this.connected = true
    this.operation = 0
    this.owned = new Set()
    this.onSubmit = event => {
      if (event.target.id !== "mission-form") return
      if (!this.connected || this.pending) {
        event.preventDefault()
        event.stopImmediatePropagation()
        return
      }

      this.pending = true
      this.sawSubmitLoading = false
      const operation = ++this.operation
      this.applyLock()
      queueMicrotask(() => {
        if (!this.pending || this.operation !== operation) return
        if (this.loading()) this.sawSubmitLoading = true
        else this.release()
      })
    }
    this.el.addEventListener("submit", this.onSubmit, true)
    this.observer = new MutationObserver(() => {
      if (!this.pending) return
      if (this.loading()) this.sawSubmitLoading = true
      else if (this.sawSubmitLoading) this.release()
    })
    this.observer.observe(this.el, {subtree: true, childList: true, attributes: true, attributeFilter: ["class"]})
  },

  loading() {
    return !!this.el.querySelector("#mission-form.phx-submit-loading")
  },

  applyLock() {
    for (const selector of ["#mission-form", "#mission-presets", "#reset-mission"]) {
      const element = this.el.querySelector(selector)
      if (element && !element.inert) {
        element.inert = true
        this.owned.add(element)
      }
    }
    this.el.dataset.missionPending = "true"
    this.el.setAttribute("aria-busy", "true")
  },

  release() {
    this.operation++
    this.pending = false
    this.sawSubmitLoading = false
    for (const element of this.owned) element.inert = false
    this.owned.clear()
    this.el.removeAttribute("data-mission-pending")
    this.el.removeAttribute("aria-busy")
  },

  updated() {
    if (this.pending) this.applyLock()
  },

  disconnected() {
    this.connected = false
    this.release()
  },

  reconnected() {
    this.release()
    this.connected = true
  },

  destroyed() {
    this.el.removeEventListener("submit", this.onSubmit, true)
    this.observer.disconnect()
    this.release()
  }
}

export default MissionFormLock
