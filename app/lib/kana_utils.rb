# frozen_string_literal: true

# Utility module for Hiragana/Katakana
module KanaUtils
  ROMA2KANA_CHARS = { a: 'あいうえお',
                      ka: 'かきくけこ',
                      sa: 'さしすせそ',
                      ta: 'たちつてと',
                      na: 'なにぬねの',
                      ha: 'はひふへほ',
                      ma: 'まみむめも',
                      ya: 'やゆよ',
                      ra: 'らりるれろ',
                      wa: 'わをん',
                      zz: '' }.freeze

  ROMA2KANA = { a: 'あ', i: 'い', u: 'う', e: 'え', o: 'お',
                ka: 'か', ki: 'き', ku: 'く', ke: 'け', ko: 'こ',
                sa: 'さ', si: 'し', su: 'す', se: 'せ', so: 'そ',
                ta: 'た', ti: 'ち', tu: 'つ', te: 'て', to: 'と',
                na: 'な', ni: 'に', nu: 'ぬ', ne: 'ね', no: 'の',
                ha: 'は', hi: 'ひ', hu: 'ふ', he: 'へ', ho: 'ほ',
                ma: 'ま', mi: 'み', mu: 'む', me: 'め', mo: 'も',
                ya: 'や', yu: 'ゆ', yo: 'よ',
                ra: 'ら', ri: 'り', ru: 'る', re: 'れ', ro: 'ろ',
                wa: 'わ', wo: 'を', nn: 'ん',
                zz: nil }.freeze

  def roma2kana_chars(roma_sym)
    ROMA2KANA_CHARS[roma_sym].chars
  end
  module_function :roma2kana_chars

  def roma2kana_char(roma_sym, other: '')
    ROMA2KANA[roma_sym] || other
  end
  module_function :roma2kana_char

  def kana2roma_chars(kana)
    ROMA2KANA_CHARS.each_pair do |roma, kana_str|
      idx = kana_str.index(kana)
      return roma, idx if idx
    end
    [:zz, 0]
  end
  module_function :kana2roma_chars
end
