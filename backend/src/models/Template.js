const mongoose = require('mongoose');

const TemplateSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    description: { type: String, required: true },
    category: {
      type: String,
      enum: ['productivity', 'academic', 'project', 'fitness', 'career', 'personal', 'other'],
      default: 'productivity',
    },
    durationWeeks: { type: Number, default: 4 },
    durationMonths: { type: Number, default: 1 },
    tasksTemplate: [
      {
        title: String,
        description: String,
        dayOffset: Number, // day offset from start date
        repeatType: String,
      },
    ],
    milestonesTemplate: [
      {
        title: String,
        dayOffset: Number,
      },
    ],
    weeklyStructure: [
      {
        weekNumber: Number,
        focus: String,
        goals: [String],
      },
    ],
    monthlyStructure: [
      {
        monthIndex: Number,
        focus: String,
        goals: [String],
      },
    ],
    usageCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Template', TemplateSchema);
