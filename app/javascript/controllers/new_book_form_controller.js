import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="new-book-form"
export default class extends Controller {
  static targets = ["manualForm"]

  connect() {
    console.log("New book form controller connected")
  }

  // 手動入力フォームを表示（UI補助のみ）
  toggleToManual() {
    // ISBN検索カードを非表示
    const isbnCard = this.element.querySelector('.card:first-child')
    if (isbnCard) isbnCard.style.display = 'none'
    
    // search_resultフレームを非表示
    const searchFrame = document.getElementById('search_result')
    if (searchFrame) searchFrame.style.display = 'none'
    
    // 手動入力フォームを表示
    this.manualFormTarget.style.display = 'block'
  }

  // ISBN検索フォームに戻る（UI補助のみ）
  backToSearch() {
    // 手動入力フォームを非表示
    this.manualFormTarget.style.display = 'none'
    
    // ISBN検索カードを表示
    const isbnCard = this.element.querySelector('.card:first-child')
    if (isbnCard) isbnCard.style.display = 'block'
    
    // search_resultフレームを表示
    const searchFrame = document.getElementById('search_result')
    if (searchFrame) searchFrame.style.display = 'block'
  }
}