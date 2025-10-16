import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="book-import"
export default class extends Controller {
  static targets = ["isbnSearchForm", "manualForm", "searchResults"]

  connect() {
    console.log("Book import controller connected")
  }

  // 手動入力フォームを表示
  toggleToManual() {
    this.isbnSearchFormTarget.style.display = 'none'
    this.manualFormTarget.style.display = 'block'
  }

  // ISBN検索フォームに戻る
  backToSearch() {
    this.manualFormTarget.style.display = 'none'
    this.isbnSearchFormTarget.style.display = 'block'
    this.searchResultsTarget.style.display = 'none'
  }
}