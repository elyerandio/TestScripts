from django.conf.urls import patterns, include, url
from views import *

from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'mysite.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    #url(r'^admin/', include(admin.site.urls)),
	url(r'^hello/$', hello),
	url(r'^time/$', current_datetime),
	url(r'^time/plus/(\d{1,2})/$', hours_ahead),
)
