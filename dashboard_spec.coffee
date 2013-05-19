#= require dashboard
#= require mock-ajax

describe "Dashboard - getData()", ->
  beforeEach ->
    @dashboard = Dashboard
    jasmine.Ajax.useMock()

  describe "when the report is ready on the first iteration", ->
    it "should return the dashboard data", ->
      that = this

      @dashboard.getData 'lesson_leaders', {}, (data) ->
        that.data = data

      request = mostRecentAjaxRequest()
      expect(request.url).toBe('/dashboard/queries')
      expect(request.method).toBe('POST')
      request.response { status: 200, responseText: '{"id": "REPORT_ID" }' }

      waits(1000)

      runs ->
        request = mostRecentAjaxRequest()
        request.response { status: 200, responseText: '{"is_ready": true, "data":"DATA" }' }

        expect(that.data).toEqual 'DATA'
