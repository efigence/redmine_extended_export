$(function(){
  $('#csv-export-options').after( $('#xlsx-export-options') );

  $('a.csv').parent().after( $('a.xlsx').parent() );
  $('a.xlsx').parent().after( $('a.pdf').parent() );

  $('p.other-formats').last().remove();

  $('a.csv').css("margin-right", "3px");
  $('a.xlsx').css("margin-right", "3px");
});
