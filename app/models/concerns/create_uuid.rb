module CreateUuid
  def uuid
    SecureRandom.uuid[0..4]
  end
end
