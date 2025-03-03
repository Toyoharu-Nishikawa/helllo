export const TAG_NAME = "my-main"

const createHTML = (params) => `
<style>
  :host{
    display: grid;
    grid-template-rows:    1fr 1fr;
    grid-template-columns: 1fr 1fr;
    overflow:hidden;
  }
  *{
    padding: 20px;
  }
  [name="top-left"] {
    grid-row: 1/2;
    grid-column: 1/2;
    overflow:hidden;
  }
  [name="top-right"] {
    grid-row: 1/2;
    grid-column: 2/3;
    overflow:hidden;
  }
  [name="bottom-left"] {
    grid-row: 2/3;
    grid-column: 1/2;
    overflow:hidden;
  }
  [name="bottom-right"]{
    grid-row: 2/3;
    grid-column: 2/3;
    overflow:hidden;
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
    
    const shadow = this.attachShadow({mode: 'open'})
    const HTML = createHTML()
    const content = this.innerHTML
    const html = HTML + content 
    shadow.setHTMLUnsafe(html)
  }
}

customElements.define(TAG_NAME, CustomElem)
