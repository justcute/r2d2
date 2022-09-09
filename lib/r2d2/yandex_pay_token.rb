module R2D2
  class YandexPayToken < GooglePayToken
    def sender_id
      'Yandex'
    end
  end
end
