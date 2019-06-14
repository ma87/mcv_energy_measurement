function sub_elems = plot_elems(elems, filters, groups)
  
 %  hits = arrayfun(@(x) x.DAY == day ,elems);
 % elems_day = elems(hits);
  
  if length(filters) > 0
    idx = arrayfun(@(e) is_filtered(e, filters), elems);
    filtered_elems = elems(idx);
  else
    filtered_elems = elems(:);
  end
  
  [sub_elems, legs] = group_elems(filtered_elems, groups);
  
  figure
  hold on
  
  %cellfun(@(e) plot([e(:).TIME_ELAPSED], [e(:).ENERGY_CONSUMED], '*'), sub_elems);
  cellfun(@(e) plot_elem(e), sub_elems);
  
  plot_linear_regression(filtered_elems);
  legs{length(legs)+1} = "linear regression";
  
  legend(legs, "location", "southeast")
  
  hold off  
  
endfunction

function plot_linear_regression(elems)
    group_linear_regression = {"USER","LANGUAGE","DAY"};
    sub_elems = group_elems(elems, group_linear_regression);
    
    t = cellfun(@(e) [mean([e.TIME_ELAPSED])], sub_elems);
    e = cellfun(@(e) [mean([e.ENERGY_CONSUMED])], sub_elems);
    m = length(t);
    T = [ones(m, 1) t'];
    theta = (pinv(T'*T))*T'*e';
    plot(T(:,2), T*theta, '-')
    
endfunction

function [sub_elems, legends] = group_elems(elems, groups)
    legends = {};
    sub_elems = [];
    number_legends = 1;
    for i=1:length(elems)
      legend_elem = get_legend_name(elems(i), groups);
      if ~any(strcmp(legends, legend_elem))
        legends{number_legends} = legend_elem;
        number_legends = number_legends + 1;
      endif
      
    endfor
    
    for i=1:number_legends-1
      legend_elem = legends{i};
      idx = arrayfun(@(e) strcmp(get_legend_name(e, groups), legend_elem), elems);
      sub_elems{i} = elems(idx);
    endfor
end

function legend_name = get_legend_name(elem, groups)
  legend_name = "";
  for i=1:length(groups)-1
    legend_name = [legend_name, num2str(elem.(groups{i})), "--"];
  end
  legend_name = [legend_name, num2str(elem.(groups{end}))];
endfunction

function res = is_filtered(elem, filters)
  res = 1;
  for f=1:length(filters)
    res &= filters(f).func(elem.(filters(f).name), filters(f).value);
  end
endfunction

function plot_elem(x)
  e = mean([x(:).ENERGY_CONSUMED]);
  t = mean([x(:).TIME_ELAPSED]);
  err_e = std([x(:).ENERGY_CONSUMED]);
  err_t = std([x(:).TIME_ELAPSED]);
  
  plot(t,e, "+");
  #errorbar(t, e, err_e, "~.r");
endfunction
