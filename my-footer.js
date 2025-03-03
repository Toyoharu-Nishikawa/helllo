export const TAG_NAME = "my-footer"

const createHTML = (params) => `
<style>
  :host{
    border-top: 1px solid #DCDCDC;
    background: #E6E6FA;
    display: flex;
    justify-content: center;
    align-items: center;
  }
</style>
<small></small>
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
    shadow.setHTMLUnsafe(HTML)
    const smallElem = shadow.querySelector("small")
    const content = this.innerHTML
    smallElem.setHTMLUnsafe(content)
  }
}

customElements.define(TAG_NAME, CustomElem)
