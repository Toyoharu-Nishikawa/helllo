export const TAG_NAME = "my-header"

const createHTML = (params) => `
<style>
  :host{
    background: ghostwhite;
    display: flex;
    align-items: center;
    border-bottom: 1px solid #DCDCDC;
  }
  h1 {
    padding: 0 30px;
    margin: 0px;
  }
</style>
<h1></h1>
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
    const smallElem = shadow.querySelector("h1")
    const content = this.innerHTML
    smallElem.setHTMLUnsafe(content)
  }
}

customElements.define(TAG_NAME, CustomElem)
