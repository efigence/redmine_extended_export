$(function() {
  $('a.pdf').parent().after($('a.odt').parent());
  $('p.other-formats').last().remove();
});
