function [elems, h] = get_elems_csv(csv_file)
  f = fopen (csv_file, "r");
  header = fgetl(f);
  h = strsplit(header, ',');
  
  l = fgetl(f);
  number_elems = 0;
  current_elem = "";
  current_elem_index = 0;
  current_index = 1;
  elems = [];
  while(l > 0)
    data = strsplit(l, ',');
    
    if length(h) == length(data)
      for i=1:length(h)
        if strcmp(h{i}, "USER") || strcmp(h{i}, "LANGUAGE")
          elems(current_index).(h{i}) = data{i};  
        else
          elems(current_index).(h{i}) = str2double(data{i});
        end
      end
      current_index = current_index + 1;
    end
        
    l = fgetl(f);
  end
endfunction
