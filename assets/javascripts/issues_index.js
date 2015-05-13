$(function(){
  $('a.atom').parent().after( $('a.xlsx').parent() );
  $('p.other-formats').last().remove();
  $('a.atom').css("margin-right", "3px");

  var csv_desc_label = $('form#csv-export-form input[name="description"]').parent();
  csv_desc_label.after( $('label#csv-comments') );
});
