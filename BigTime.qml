//  musescore-bigtime-plugin
//  Copyright (C) 2022  RunasSudo (Lee Yingtong Li)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import QtQuick 2.0
import MuseScore 3.0

MuseScore {
	version: "1.4"
	description: "Large time signatures"
	menuPath: "Plugins.BigTime"
	
	onRun: {
		
		// -----------------------
		// Configurable parameters
		
		// Which staves (0-indexed) to show large time signatures
		var TIMESIG_STAVES = [0];
		
		// Text style for large time signatures
		var TIMESIG_STYLE = Tid.USER1;
		
		// Font face (null to use style default)
		var TIMESIG_FACE = "Bravura Text";
		
		// Size in points (null to use style default)
		var TIMESIG_SIZE = 200;
		
		// Line separation (null to use style default)
		// NYI - Not exposed in plugin API
		//var TIMESIG_LINESEP = 0.34;
		
		// Scaling factor relative to native time signature width
		var TIMESIG_WIDTH = 2.5;
		
		// Controls which Unicode codepoints to use for time signatures
		// Refers to the codepoint for "0", others calculated by offset
		// 0x30: Standard ASCII numbers
		// 0xE080: SMuFL time signatures
		// 0xF440: SMuFL large time signatures (Bravura)
		// 0xF45D: SMuFL small time signatures (Bravura)
		// 0xF506: SMuFL narrow time signatures (Bravura)
		var TIMESIG_CODEPOINT_BASE = 0xF440;
		
		
		
		
		// ------------------
		// PLUGIN CODE BEGINS
		// ------------------
		
		if (!curScore) {
			Qt.quit();
		}
		
		var cursor = curScore.newCursor(); // TODO: Is this necessary?
		
		// ----------
		// Full score
		
		// Delete all large time signatures so they can be rebuilt
		var segment = curScore.firstSegment();
		while (segment) {
			for (var i = 0; i < segment.annotations.length; i++) {
				var annotation = segment.annotations[i];
				if (annotation.name === "StaffText" && annotation.subStyle === TIMESIG_STYLE) {
					removeElement(annotation);
				}
			}
			segment = segment.next;
		}
		
		// Hide and reserve space from native time signatures
		// Do this first to allow page layout to reflow
		var segment = curScore.firstSegment();
		while (segment) {
			if (segment.segmentType == 0x10) { // SegmentType.TimeSig
				for (var track = 0; track < curScore.ntracks; track++) {
					var element = segment.elementAt(track);
					if (element && element.name === "TimeSig") {
						//console.log("tick:", segment.tick, "track:", track, "ts:", element.timesig.str);
						
						element.color.a = 0; // Sets alpha to 0
						element.scale.width = TIMESIG_WIDTH;
					}
				}
			}
			segment = segment.next;
		}
		
		function mkSmuflString(num) {
			var str = "" + num;
			var out = "";
			for (var i = 0; i < str.length; i++) {
				out += String.fromCharCode(TIMESIG_CODEPOINT_BASE + str.charCodeAt(i) - 0x30);
			}
			return out;
		}
		
		// Add large time signatures
		var segment = curScore.firstSegment();
		while (segment) {
			if (segment.segmentType == 0x10) { // SegmentType.TimeSig
				for (var track = 0; track < curScore.ntracks; track++) {
					var element = segment.elementAt(track);
					if (element && element.name === "TimeSig") {
						// Check if in TIMESIG_STAVES
						for (var itss = 0; itss < TIMESIG_STAVES.length; itss++) {
							if (track === TIMESIG_STAVES[itss] * 4) {
								var txtTimeSig = newElement(Element.STAFF_TEXT);
								txtTimeSig.autoplace = false;
								txtTimeSig.subStyle = TIMESIG_STYLE;
								txtTimeSig.fontFace = TIMESIG_FACE;
								txtTimeSig.fontSize = TIMESIG_SIZE;
								txtTimeSig.align = Align.HCENTER | Align.TOP;
								txtTimeSig.text = mkSmuflString(element.timesig.numerator) + "\n" + mkSmuflString(element.timesig.denominator);
								
								cursor.track = track;
								cursor.rewindToTick(segment.tick);
								
								txtTimeSig.visible = false; // For part scores
								cursor.add(txtTimeSig);
								txtTimeSig.visible = true; // Show in full score
								
								// Calculate required offset
								var offset = element.pagePos.x + element.bbox.width/2 - txtTimeSig.pagePos.x;
								txtTimeSig.offsetX += offset;
								
								break; // for (var tss in TIMESIG_STAVES)
							}
						}
					}
				}
			}
			segment = segment.next;
		}
		
		// -----------
		// Part scores
		
		for (var i = 0; i < curScore.excerpts.length; i++) {
			var partScore = curScore.excerpts[i].partScore;
			
			if (partScore.is(curScore)) {
				continue;
			}
			
			// Make native time signatures normal
			var segment = partScore.firstSegment();
			while (segment) {
				if (segment.segmentType == 0x10) { // SegmentType.TimeSig
					for (var track = 0; track < partScore.ntracks; track++) {
						var element = segment.elementAt(track);
						if (element && element.name === "TimeSig") {
							element.color.a = 1;
							element.scale.width = 1;
						}
					}
				}
				segment = segment.next;
			}
		}
		
		Qt.quit();
	}
}
