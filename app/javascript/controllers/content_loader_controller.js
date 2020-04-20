import { Controller } from "stimulus"

export default class extends Controller {
  initialize() {
    if(!this.loaded) {
      this.load()
    }
  }

  load() {
    this.loaded = true
    fetch(this.data.get('url'))
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html

        if (this.simplebarController) {
          this.simplebarController.reinit()
        }
      })
  }

  get loaded() {
    return this.data.get("loaded") == 'true'
  }

  set loaded(value) {
    this.data.set("loaded", value)
  }

  get simplebarController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "simplebar")
  }
}
