export const TAG_NAME = "my-menu"

const createHTML = (params) => `
<style>
  :host{
    border-bottom: 1px solid #DCDCDC;
    background: ghostwhite;
    --md-icon-button-icon-size: 48px;
    display: flex;
    align-items: center;
    gap: 40px;
  }
</style>
`

export const CustomElem = class extends HTMLElement {
  constructor(){
    super()
  }
  connectedCallback() {
    const internals = this.attachInternals()
    const isShadow = internals.shadowRoot
    if(isShadow) return

    const shadow = this.attachShadow({mode: 'open'});
    const HTML = createHTML()
    const content = this.innerHTML
    const html = HTML + content 
    shadow.setHTMLUnsafe(html)
  }
}

customElements.define(TAG_NAME, CustomElem)
