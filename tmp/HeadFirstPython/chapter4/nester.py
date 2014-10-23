import sys
def print_lol(the_list, indent=False, level=0, fh=sys.stdout):
	for each_item in the_list:
		if isinstance(each_item, list):
			print_lol(each_item,level+1, fh)
		else:
			for tab_stop in range(level):
				print("\t", end='', file=fh)
			print(each_item, file=fh)
