class MergeError < StandardError
  class ProductsNeedMergingError < MergeError
    attr_reader :merge_list

    def initialize(merge_list)
      @merge_list = merge_list
    end
  end

  class NoPossibleMergeError < MergeError
    attr_reader :unknown_id, :destination

    def initialize(unknown_id, destination)
      @unknown_id = unknown_id
      @destination = destination
    end
  end
end
