class PathWalker
  def self.build_path_steps(path_locs, start_loc, start_dir, rule)
    path = []

    wall_dir = nil
    Vec::NEIGHBOR_VECS.each do |n_vec|
      if !path_locs.include?(start_loc + n_vec)
        wall_dir = n_vec
        break
      end
    end

    case wall_dir
    when Vec::DOWN
      start_dir = Vec::LEFT
    when Vec::UP
      start_dir = Vec::RIGHT
    when Vec::LEFT
      start_dir = Vec::UP
    when Vec::RIGHT
      start_dir = Vec::DOWN
    else # this shouldn't happen
      start_dir = Vec::RIGHT
    end

    loc = start_loc
    dir = start_dir
    first_next = nil
    while true
      # puts "loc=#{loc} dir=#{dir} first_next=#{first_next} path=#{path}"
      next_loc = nil
      rule.each do |rel_search_dir|
        abs_search_dir = RELATIVE_DIR_MAP[dir][rel_search_dir]
        search_loc = loc + abs_search_dir # RELATIVE_DIR_MAP[dir][rel_search_dir]
        # puts "  Checking rel_search_dir=#{rel_search_dir} abs_search_dir=#{abs_search_dir} => search_loc=#{search_loc}"
        if path_locs.include?(search_loc)
          next_loc = search_loc
          dir = abs_search_dir
          break
        end
      end
      # puts "  next_loc=#{next_loc}"
      if loc == start_loc and next_loc == first_next
        return path
      end
      path << loc
      first_next ||= next_loc
      loc = next_loc
    end
  end
end

# path_locs = [
#   vec(3,2),
#   vec(2,3),
#   vec(3,3),
#   vec(4,3),
#   vec(5,3),
# ]
#
# start_loc = vec(4,3)
# start_dir = Vec::RIGHT
