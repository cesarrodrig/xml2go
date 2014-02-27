XML2Go
=========================

Convert an XML file to a Go struct.

Use
-------------------------
    bundle exec ruby lib/xml2go.rb <xml_file> <go_output_file>

Example
-------------------------

Input:

    <?xml version="1.0"?>
    <?xml-stylesheet type="text/css" href="nutrition.css"?>
    <nutrition>
        <food>
            <name>Avocado Dip</name>
            <mfr>Sunnydale</mfr>
            <serving units="g">29</serving>
            <calories total="110" fat="100"/>
            <total-fat>11</total-fat>
            <saturated-fat>3</saturated-fat>
            <cholesterol>5.0</cholesterol>
            <sodium>210</sodium>
            <carb>2</carb>
            <fiber>0</fiber>
            <protein>1.1</protein>
            <natural>false</natural>
        </food>
    </nutrition>

Output:

    package main

    type Food struct {
        Name         string    `xml:"name"`
        Mfr          string    `xml:"mfr"`
        Serving      int       `xml:"serving"`
        Calories     string    `xml:"calories"`
        TotalFat     int       `xml:"total-fat"`
        SaturatedFat int       `xml:"saturated-fat"`
        Cholesterol  float64   `xml:"cholesterol"`
        Sodium       int       `xml:"sodium"`
        Carb         int       `xml:"carb"`
        Fiber        int       `xml:"fiber"`
        Protein      float64   `xml:"protein"`
        Natural      bool      `xml:"natural"`
    }

    type Nutrition struct {
        Food Food `xml:"food"`
    }

    type Document struct {
        Nutrition Nutrition `xml:"nutrition"`
    }
