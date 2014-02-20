from django.http import HttpResponse
from datetime import datetime, timedelta

def hello(request):
	return HttpResponse('Hello world')


def current_datetime(request):
	now = datetime.now()
	html = "<html><body>It is now %s.</body></html>" % now
	return HttpResponse(html)

def hours_ahead(request, offset):
	try:
		offset = int(offset)
	except ValueError:
		raise Http404()

	dt = datetime.now() + timedelta(hours = offset)
	assert False
	html = "<html><body>In %d hour(s), it will be %s</body></html>" % (offset,dt)
	return HttpResponse(html)

