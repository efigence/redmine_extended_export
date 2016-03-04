$(function() {
	$('#issue_tree').append($('#subtasks-export'));

	if ($('#related-export').length > 0) {
		$('#relations').css("margin-bottom", "28px");
		$('#relations table.list').after($('#related-export'));
	}
});
