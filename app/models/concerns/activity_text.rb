# 活動(Routine::LEVELS の1件)を画面用の文言にする。表示の組み立てはここ1か所だけ。
#   label に %{value} があればその位置に、なければ末尾に「値」(10秒 / 1回 など)を入れる。
#   note は末尾に「 (日光浴)」の形で付く。
module ActivityText
  module_function

  # 秒数 → 「10秒」「1分」「1分30秒」
  def duration(seconds)
    seconds = seconds.to_i
    minutes, rest = seconds.divmod(60)
    return "#{rest}秒" if minutes.zero?

    rest.zero? ? "#{minutes}分" : "#{minutes}分#{rest}秒"
  end

  def value(activity)
    case activity[:kind]
    when :timer then duration(activity[:seconds])
    when :count, :check then activity[:amount] && "#{activity[:amount]}#{activity[:unit]}"
    end
  end

  def text(activity)
    label = activity[:label]
    value = value(activity)
    body = if label.include?("%{value}") then format(label, value: value)
           elsif value then "#{label} #{value}"
           else label
           end
    activity[:note] ? "#{body} (#{activity[:note]})" : body
  end
end
