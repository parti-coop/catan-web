import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['viewContent', 'formContent', 'bodyField']

  open(event) {
    event.preventDefault()

    this.viewContentTarget.classList.remove('show')
    this.formContentTarget.classList.add('show')
    this.bodyFieldTarget.focus()
  }

  close(event) {
    event.preventDefault()

    this.viewContentTarget.classList.add('show')
    this.formContentTarget.classList.remove('show')
  }
}