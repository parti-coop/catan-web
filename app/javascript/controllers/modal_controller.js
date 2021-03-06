import { Controller } from "stimulus";
import { smartFetch } from '../helpers/smart_fetch'
import { v4 as uuidv4 } from 'uuid'

export default class extends Controller {
  static targets = ['content']

  connect() {
    this.opened = false

    this.closeHandler = this.close.bind(this)

    document.addEventListener('modal:close', this.closeHandler)
  }

  disconnect() {
    this.opened = false

    if (this.closeHandler) {
      document.removeEventListener('modal:close', this.closeHandler)
    }
  }

  open(url) {
    document.body.classList.add("modal-open");
    this.element.setAttribute("style", "display: block;");
    this.element.classList.add("show");

    this.uuidBackdrop = uuidv4()
    document.body.insertAdjacentHTML('beforeend', `<div id="${this.uuidBackdrop}" class="modal-backdrop fade show"></div>`)

    if (url && this.hasContentTarget) {
      this.contentTarget.innerHTML = this.loading()
      this.getContent(url)
    }

    this.opened = true
  }

  close() {
    document.body.classList.remove("modal-open")
    this.element.removeAttribute("style")
    this.element.classList.remove("show")
    let backdrop = document.getElementById(this.uuidBackdrop)
    if (backdrop) {
      backdrop.remove()
    }

    this.opened = false
  }

  getContent(url) {
    if (!this.hasContentTarget) { return }

    smartFetch(url)
      .then(response => {
        if (response && response.ok) {
          return response.text()
        } else {
          this.close()
        }
      })
      .then(html => {
        if (html) {
          this.contentTarget.innerHTML = html
        }
      })
  }

  loading() {
    return `
      <div class="modal-header">
        <h6 class="modal-title">로딩 중...</h6>
        <button type="button" class="close -sm" data-action="click->modal#close" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body"><div class="mt-4 mb-4 text-center"><i class="fa fa-spinner fa-pulse fa-fw text-muted"></i></div></div>
    `
  }
}