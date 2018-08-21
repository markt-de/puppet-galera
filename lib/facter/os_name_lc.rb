Facter.add(:os_name_lc) do
  setcode do
    if not Facter.value(:os).nil?
      Facter.value(:os)['name'].downcase
    end
  end
end
