import { Controller } from "stimulus"
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  static targets = ['menuActivation', 'channelActivation', 'channelCollapse', 'folderActivation', 'folderCollapse', 'collectionActivationController']

  consume(event) {
    const menuSlug = event.detail.menuSlug
    const channelId = +event.detail.channelId
    const folderId = +event.detail.folderId

    const currentMenuActivation = this.findElement(this.menuActivationTargets, 'menuSlug', menuSlug)
    const currentChannelActivation = this.findElementAsNumber(this.channelActivationTargets, 'channelId', channelId)
    const currentFolderActivation = this.findElementAsNumber(this.folderActivationTargets, 'folderId', folderId)
    const currentChannelCollapse = this.findElementAsNumber(this.channelCollapseTargets, 'channelId', channelId)
    const currentFolderCollapse = this.findElementAsNumber(this.folderCollapseTargets, 'folderId', folderId)

    const eventActivation = new CustomEvent('group-sidebar-activation', {
      bubbles: false
    })

    if (currentChannelActivation) {
      if (!currentFolderActivation) {
        currentChannelActivation.dispatchEvent(eventActivation)
      } else {
        currentFolderActivation.dispatchEvent(eventActivation)
      }
    } else if (currentMenuActivation) {
      currentMenuActivation.dispatchEvent(eventActivation)
    } else {
      if (this.collectionActivationControllerTarget) {
        this.collectionActivationControllerTarget.dispatchEvent(eventActivation)
      }
    }

    if (currentChannelCollapse) {
      const event = new CustomEvent('group-sidebar-collapse-show', {
        bubbles: false
      })
      currentChannelCollapse.dispatchEvent(event)
    }
    if (currentFolderCollapse) {
      this.showAncestorFolderCollapses(currentFolderCollapse)
    }

    this.channelCollapseTargets.forEach(el => {
      if (el === currentChannelCollapse) { return }
      const event = new CustomEvent('group-sidebar-collapse-hide', {
        bubbles: false
      })
      el.dispatchEvent(event)
    })

    if (!currentChannelCollapse && !currentFolderCollapse) {
      this.folderCollapseTargets.forEach(el => {
        const event = new CustomEvent('group-sidebar-collapse-hide', {
          bubbles: false
        })
        el.dispatchEvent(event)
      })
    }
  }

  showAncestorFolderCollapses(currentFolderCollapse) {
    if (!currentFolderCollapse) { return }

    const parentElement = currentFolderCollapse.parentElement
    if (!parentElement) { return }

    const parentFolderCollapse = parentElement.closest(`[data-target~="${this.identifier}.folderCollapse"]`)
    if (!parentFolderCollapse || !this.element.contains(parentFolderCollapse)) { return }

    const event = new CustomEvent('group-sidebar-collapse-show', {
      bubbles: false
    })
    parentFolderCollapse.dispatchEvent(event)

    this.showAncestorFolderCollapses(parentFolderCollapse)
  }

  findElementAsNumber(targets, name, value) {
    if (!value) {
      return null
    }

    return targets.find(el => {
      const paramMap = new ParamMap(this, el)
      if (!paramMap.get(name)) { return false }

      return (value === +paramMap.get(name))
    })
  }

  findElement(targets, name, value) {
    if (!value) {
      return null
    }

    return targets.find(el => {
      const paramMap = new ParamMap(this, el)
      if (!paramMap.get(name)) { return false }

      return (value === paramMap.get(name))
    })
  }
}