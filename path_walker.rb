class PathWalker
  def self.build_path_steps(path_locs, start_loc, rule)
    path = []

    wall_dir = nil
    Vec::NEIGHBOR_VECS.each do |n_vec|
      if !path_locs.include?(start_loc + n_vec)
        wall_dir = n_vec
        break
      end
    end
    # get the next value in rule
    start_dir = rule[(rule.index(wall_dir)+1)%rule.length]

    loc = start_loc
    dir = start_dir
    first_next = nil
    while true
      next_loc = nil
      rule.each do |rel_search_dir|
        abs_search_dir = RELATIVE_DIR_MAP[dir][rel_search_dir]
        search_loc = loc + abs_search_dir
        if path_locs.include?(search_loc)
          next_loc = search_loc
          dir = abs_search_dir
          break
        end
      end
      if loc == start_loc and next_loc == first_next
        puts "WARNING: did not use all transparent path locations" unless (path_locs - path).empty?
        return path
      end
      path << loc
      first_next ||= next_loc
      loc = next_loc
    end
  end
end
